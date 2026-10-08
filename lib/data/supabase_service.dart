import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../env.dart';
import 'models.dart';

const _uuidGen = Uuid();

/// Thin wrapper the rest of the app calls instead of touching
/// [Supabase.instance] directly, kept close to the actual table/column
/// names so it stays easy to cross-check against the live schema.
SupabaseClient get supa => Supabase.instance.client;

/// Deep link used to return into the app after an OAuth redirect on mobile.
/// Configured in the Android manifest / iOS Info.plist alongside this.
const String oauthRedirectUri = 'io.supabase.livispace://login-callback';

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  User? get currentUser => supa.auth.currentUser;
  bool get isSignedIn => currentUser != null;
  Stream<AuthState> get onAuthStateChange => supa.auth.onAuthStateChange;

  Future<bool> isUsernameAvailable(String username) async {
    final result = await supa.rpc(
      'check_username_available',
      params: {'p_username': username},
    );
    return result as bool;
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
    required String username,
  }) async {
    final available = await isUsernameAvailable(username);
    if (!available) {
      throw const AuthException('That username is already taken.');
    }

    // The `public."User"` row is created server-side by a trigger on
    // `auth.users` (the client has no INSERT grant on that table), so the
    // full name/username are passed as signup metadata for the trigger to
    // read rather than inserted directly.
    final response = await supa.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': fullName, 'username': username},
    );
    final user = response.user;
    if (user == null) {
      throw const AuthException('Sign up failed. Please try again.');
    }

    // Safety net in case the trigger didn't pick up the metadata keys above;
    // ignored on failure since the trigger is the source of truth.
    try {
      await supa
          .from('User')
          .update({'FullName': fullName, 'UserName': username})
          .eq('UserID', user.id);
    } on PostgrestException {
      // Ignore — see comment above.
    }
  }

  /// SRS FR11: five consecutive failed sign-ins lock that email for 15
  /// minutes. This only throttles the app on this device — a determined
  /// attacker can call the Supabase API directly — so server-side
  /// rate limiting in the Supabase dashboard is still the real control.
  static const int maxFailedSignIns = 5;
  static const Duration lockoutDuration = Duration(minutes: 15);
  final Map<String, ({int failures, DateTime? lockedUntil})> _signInAttempts =
      {};

  /// Signs in with an email address or a username (SRS UC2). A username is
  /// resolved server-side by the `username-login` edge function, so the app
  /// never sees the account's email.
  Future<void> signIn({
    required String identifier,
    required String password,
  }) async {
    final key = identifier.trim().toLowerCase();
    final lockedUntil = _signInAttempts[key]?.lockedUntil;
    if (lockedUntil != null && lockedUntil.isAfter(DateTime.now())) {
      final minutes = lockedUntil.difference(DateTime.now()).inMinutes + 1;
      throw AuthException(
        'Too many failed attempts. Try again in $minutes minute'
        '${minutes == 1 ? '' : 's'}.',
      );
    }

    try {
      if (identifier.contains('@')) {
        await supa.auth.signInWithPassword(
          email: identifier.trim(),
          password: password,
        );
      } else {
        await _signInWithUsername(identifier.trim(), password);
      }
    } on AuthRetryableFetchException {
      rethrow; // Network trouble is not a wrong password.
    } on AuthException {
      final failures = (_signInAttempts[key]?.failures ?? 0) + 1;
      final locked = failures >= maxFailedSignIns;
      _signInAttempts[key] = (
        failures: locked ? 0 : failures,
        lockedUntil: locked ? DateTime.now().add(lockoutDuration) : null,
      );
      rethrow;
    }
    _signInAttempts.remove(key);

    final user = currentUser;
    if (user != null) {
      await supa
          .from('User')
          .update({'LastSignIn': DateTime.now().toUtc().toIso8601String()})
          .eq('UserID', user.id);
    }
  }

  Future<void> _signInWithUsername(String username, String password) async {
    final FunctionResponse response;
    try {
      response = await supa.functions.invoke(
        'username-login',
        body: {'username': username, 'password': password},
      );
    } on FunctionException catch (e) {
      final details = e.details;
      final message = details is Map ? details['error']?.toString() : null;
      // 4xx is a rejected login and counts toward the lockout; anything
      // else is a server problem, which should not.
      if (e.status >= 500) {
        throw Exception(message ?? 'Sign in failed. Please try again.');
      }
      throw AuthException(message ?? 'Invalid login credentials');
    }
    final data = response.data;
    final refreshToken = data is Map ? data['refresh_token'] as String? : null;
    if (refreshToken == null) {
      throw const AuthException('Invalid login credentials');
    }
    await supa.auth.setSession(refreshToken);
  }

  Future<void> signInWithGoogle() async {
    await supa.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: kIsWeb ? null : oauthRedirectUri,
      authScreenLaunchMode: kIsWeb
          ? LaunchMode.platformDefault
          : LaunchMode.externalApplication,
    );
  }

  Future<void> resetPasswordForEmail(String email) {
    return supa.auth.resetPasswordForEmail(email);
  }

  Future<void> signOut() => supa.auth.signOut();

  Future<bool> isAdmin() async {
    if (currentUser == null) return false;
    final result = await supa.rpc('is_admin');
    return result as bool? ?? false;
  }
}

class UserRepository {
  UserRepository._();
  static final UserRepository instance = UserRepository._();

  Future<AppUserProfile?> fetchProfile(String userId) async {
    final row = await supa
        .from('User')
        .select()
        .eq('UserID', userId)
        .maybeSingle();
    if (row == null) return null;
    return AppUserProfile.fromJson(row);
  }

  Future<AppUserProfile> updateProfile({
    required String userId,
    String? fullName,
    String? bio,
    String? location,
    String? phone,
  }) async {
    final updates = <String, dynamic>{
      'FullName': ?fullName,
      'Bio': ?bio,
      'Location': ?location,
      'Phone': ?phone,
    };
    final row = await supa
        .from('User')
        .update(updates)
        .eq('UserID', userId)
        .select()
        .single();
    return AppUserProfile.fromJson(row);
  }

  /// Counts the user's floor plans and the rooms detected across them, for
  /// the profile screen's stat tiles.
  Future<({int projects, int rooms})> fetchStats(String userId) async {
    final floorPlans = await supa
        .from('FloorPlan')
        .select('FloorPlanID')
        .eq('UserID', userId);
    final floorPlanIds = [
      for (final row in floorPlans) row['FloorPlanID'] as String,
    ];
    if (floorPlanIds.isEmpty) return (projects: 0, rooms: 0);

    final rooms = await supa
        .from('Room')
        .select('RoomID')
        .inFilter('FloorPlanID', floorPlanIds);
    return (projects: floorPlanIds.length, rooms: rooms.length);
  }

  /// Submits an account-deletion request for an admin to review, matching
  /// the `DeletionRequest` table rather than deleting the account directly.
  Future<void> requestAccountDeletion(AppUserProfile profile) async {
    // Same rule as the web app: one pending request per user.
    final existing = await supa
        .from('DeletionRequest')
        .select('RequestID')
        .eq('UserID', profile.userId)
        .ilike('Status', 'pending')
        .maybeSingle();
    if (existing != null) {
      throw const AuthException('You already have a pending deletion request.');
    }
    await supa.from('DeletionRequest').insert({
      'UserID': profile.userId,
      'Username': profile.userName,
      'Email': profile.email,
      'FullName': profile.fullName,
      'Status': 'pending',
    });
  }

  /// Withdraws the user's own pending deletion request.
  Future<void> cancelDeletionRequest(String userId) {
    return supa
        .from('DeletionRequest')
        .delete()
        .eq('UserID', userId)
        .ilike('Status', 'pending');
  }

  Future<DeletionRequestRecord?> fetchOwnDeletionRequest(String userId) async {
    final row = await supa
        .from('DeletionRequest')
        .select()
        .eq('UserID', userId)
        .order('RequestedAt', ascending: false)
        .limit(1)
        .maybeSingle();
    if (row == null) return null;
    return DeletionRequestRecord.fromJson(row);
  }
}

class FloorPlanRepository {
  FloorPlanRepository._();
  static final FloorPlanRepository instance = FloorPlanRepository._();

  Future<List<FloorPlanRecord>> fetchUserFloorPlans(String userId) async {
    final rows = await supa
        .from('FloorPlan')
        .select()
        .eq('UserID', userId)
        .order('UploadDateTime', ascending: false);
    return rows.map(FloorPlanRecord.fromJson).toList();
  }

  /// Uploads image bytes to the private `floorplans` bucket under the
  /// user's own folder and returns the storage path (not a public URL —
  /// the bucket is private, so viewers must request a signed URL).
  Future<String> uploadFloorPlanImage({
    required String userId,
    required Uint8List bytes,
    required String fileExt,
  }) async {
    final path = '$userId/${DateTime.now().millisecondsSinceEpoch}.$fileExt';
    await supa.storage
        .from(SupabaseEnv.floorPlansBucket)
        .uploadBinary(path, bytes);
    return path;
  }

  Future<String> signedUrlFor(String path, {int expiresInSeconds = 3600}) {
    return supa.storage
        .from(SupabaseEnv.floorPlansBucket)
        .createSignedUrl(path, expiresInSeconds);
  }

  Future<FloorPlanRecord> createFloorPlan({
    required String userId,
    required String imagePath,
  }) async {
    final row = await supa
        .from('FloorPlan')
        .insert({
          'FloorPlanID': _uuidGen.v4(),
          'UserID': userId,
          'ImagePath': imagePath,
          'Status': 'Uploaded',
        })
        .select()
        .single();
    return FloorPlanRecord.fromJson(row);
  }

  Future<FloorPlanAnalysisRecord?> fetchAnalysis(String floorPlanId) async {
    final row = await supa
        .from('FloorPlanAnalysis')
        .select()
        .eq('FloorPlanID', floorPlanId)
        .maybeSingle();
    if (row == null) return null;
    return FloorPlanAnalysisRecord.fromJson(row);
  }

  /// Polls for the analysis row a backend pipeline is expected to populate
  /// once it has processed the uploaded image, since there is no realtime
  /// publication configured for this table. Stops once a row appears, the
  /// status reaches a terminal state, or [timeout] elapses.
  Stream<FloorPlanAnalysisRecord?> watchAnalysis(
    String floorPlanId, {
    Duration pollEvery = const Duration(seconds: 3),
    Duration timeout = const Duration(minutes: 3),
  }) async* {
    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      final analysis = await fetchAnalysis(floorPlanId);
      yield analysis;
      if (analysis != null && (analysis.isComplete || analysis.isFailed)) {
        return;
      }
      await Future<void>.delayed(pollEvery);
    }
  }

  Future<List<RoomRecord>> fetchRooms(String floorPlanId) async {
    final rows = await supa
        .from('Room')
        .select()
        .eq('FloorPlanID', floorPlanId);
    return rows.map(RoomRecord.fromJson).toList();
  }

  Future<List<StructuralElementRecord>> fetchStructuralElements(
    String roomId,
  ) async {
    final rows = await supa
        .from('StructuralElement')
        .select()
        .eq('RoomID', roomId);
    return rows.map(StructuralElementRecord.fromJson).toList();
  }

  Future<List<LayoutRecord>> fetchLayouts(String roomId) async {
    final rows = await supa
        .from('Layout')
        .select()
        .eq('RoomID', roomId)
        .order('Score', ascending: false);
    return rows.map(LayoutRecord.fromJson).toList();
  }

  Future<List<PlacedFurniture>> fetchFurnitureForLayout(String layoutId) async {
    final placements = await supa
        .from('FurnitureLayout')
        .select()
        .eq('LayoutID', layoutId);
    final result = <PlacedFurniture>[];
    for (final placementRow in placements) {
      final placement = FurnitureLayoutRecord.fromJson(placementRow);
      final link = await supa
          .from('Furniture_FurnitureLayout')
          .select('FurnitureID')
          .eq('FurnitureLayoutID', placement.furnitureLayoutId)
          .maybeSingle();
      if (link == null) continue;
      final furnitureRow = await supa
          .from('Furniture')
          .select()
          .eq('FurnitureID', link['FurnitureID'] as String)
          .maybeSingle();
      if (furnitureRow == null) continue;
      result.add(
        PlacedFurniture(
          placement: placement,
          furniture: FurnitureRecord.fromJson(furnitureRow),
        ),
      );
    }
    return result;
  }

  Future<void> selectRoomForAnalysis({
    required String floorPlanId,
    required String roomId,
  }) {
    return supa
        .from('FloorPlanAnalysis')
        .update({
          'SelectedRoomID': roomId,
          'UpdatedAt': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('FloorPlanID', floorPlanId);
  }
}

extension SelectedLayoutPersistence on FloorPlanRepository {
  /// Persists the layout the customer confirmed (SRS UC8 "Save Layout") on
  /// the floor plan's analysis row, so it survives leaving the screen and is
  /// what the 3D view is generated from.
  Future<void> saveSelectedLayout({
    required String floorPlanId,
    required String roomId,
    required String layoutId,
    required double score,
  }) {
    return supa
        .from('FloorPlanAnalysis')
        .update({
          'SelectedRoomID': roomId,
          'SelectedLayoutJSON': {
            'layoutId': layoutId,
            'roomId': roomId,
            'score': score,
            'selectedAt': DateTime.now().toUtc().toIso8601String(),
          },
          'UpdatedAt': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('FloorPlanID', floorPlanId);
  }
}

extension AnalysisLayoutPersistence on FloorPlanRepository {
  /// Saves a layout from the web pipeline's `LayoutJSON` in the same shape
  /// the web app writes (`SelectedLayoutJSON` = the full layout document,
  /// `Status` = `LayoutSelected`), so either client can reopen the choice.
  Future<void> saveSelectedAnalysisLayout({
    required String floorPlanId,
    required String roomId,
    required AnalysisLayout layout,
  }) {
    final userId = AuthService.instance.currentUser?.id;
    if (userId == null) {
      throw const AuthException('Your session expired. Please sign in again.');
    }
    return supa
        .from('FloorPlanAnalysis')
        .update({
          'SelectedRoomID': roomId,
          'SelectedLayoutJSON': layout.raw,
          'Status': 'LayoutSelected',
          'UpdatedAt': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('FloorPlanID', floorPlanId)
        .eq('UserID', userId);
  }
}

class AdminRepository {
  AdminRepository._();
  static final AdminRepository instance = AdminRepository._();

  Future<List<AdminUserRecord>> fetchUsers() async {
    final rows = await supa
        .from('User')
        .select('UserID, UserName, FullName, Email, LastSignIn, Role')
        .order('FullName', ascending: true);
    return rows.map(AdminUserRecord.fromJson).toList();
  }

  /// Pending requests only, like the web admin page. Matching is
  /// case-insensitive because older rows were written as `Pending`.
  Future<List<DeletionRequestRecord>> fetchDeletionRequests() async {
    final rows = await supa
        .from('DeletionRequest')
        .select()
        .ilike('Status', 'pending')
        .order('RequestedAt', ascending: false);
    return rows.map(DeletionRequestRecord.fromJson).toList();
  }

  /// Rejecting removes the request, as the web app does.
  Future<void> rejectRequest(String requestId) {
    return supa.from('DeletionRequest').delete().eq('RequestID', requestId);
  }

  /// Permanently deletes an account (SRS UC3). Mirrors the web app's order:
  /// the profile row and any requests go first, then the `delete-user` edge
  /// function removes the auth user after verifying the caller is an admin.
  Future<void> deleteAccount(String userId) async {
    await supa.from('User').delete().eq('UserID', userId);
    await supa.from('DeletionRequest').delete().eq('UserID', userId);
    final response = await supa.functions.invoke(
      'delete-user',
      body: {'userId': userId},
    );
    if (response.status != 200) {
      final error = (response.data is Map)
          ? (response.data as Map)['error']
          : null;
      throw Exception(
        'The profile was removed, but sign-in access could not be revoked'
        '${error == null ? '.' : ': $error'}',
      );
    }
  }

  /// Approving a deletion request deletes the account.
  Future<void> approveRequest(DeletionRequestRecord request) =>
      deleteAccount(request.userId);
}
