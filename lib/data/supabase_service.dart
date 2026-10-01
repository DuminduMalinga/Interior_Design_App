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

  Future<void> signIn({required String email, required String password}) async {
    await supa.auth.signInWithPassword(email: email, password: password);
    final user = currentUser;
    if (user != null) {
      await supa
          .from('User')
          .update({'LastSignIn': DateTime.now().toUtc().toIso8601String()})
          .eq('UserID', user.id);
    }
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
  Future<void> requestAccountDeletion(AppUserProfile profile) {
    return supa.from('DeletionRequest').insert({
      'UserID': profile.userId,
      'Username': profile.userName,
      'Email': profile.email,
      'FullName': profile.fullName,
    });
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

class AdminRepository {
  AdminRepository._();
  static final AdminRepository instance = AdminRepository._();

  Future<List<DeletionRequestRecord>> fetchDeletionRequests() async {
    final rows = await supa
        .from('DeletionRequest')
        .select()
        .order('RequestedAt', ascending: false);
    return rows.map(DeletionRequestRecord.fromJson).toList();
  }

  Future<void> rejectRequest(String requestId) {
    return supa
        .from('DeletionRequest')
        .update({'Status': DeletionStatus.rejected.raw})
        .eq('RequestID', requestId);
  }

  /// Approves a deletion request: marks it approved and invokes the
  /// `delete-user` edge function, which verifies the caller is an admin
  /// server-side before removing the target auth user.
  Future<void> approveRequest(DeletionRequestRecord request) async {
    final response = await supa.functions.invoke(
      'delete-user',
      body: {'userId': request.userId},
    );
    if (response.status != 200) {
      final error = (response.data is Map)
          ? (response.data as Map)['error']
          : null;
      throw Exception(error?.toString() ?? 'Failed to delete the account.');
    }
    await supa
        .from('DeletionRequest')
        .update({'Status': DeletionStatus.approved.raw})
        .eq('RequestID', request.requestId);
  }
}
