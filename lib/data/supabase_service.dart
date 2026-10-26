import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../env.dart';
import 'avatar.dart';
import 'detector_service.dart';
import 'layout_service.dart';
import 'models.dart';
import 'site_news.dart';

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

  Future<void> saveNotificationPrefs(
    String userId,
    NotificationPrefs prefs,
  ) async {
    await supa
        .from('User')
        .update({'NotificationPrefs': prefs.toJson()})
        .eq('UserID', userId);
  }

  /// Asks the server to email the signed-in user (`plan_ready` or
  /// `design_saved`). The server checks their email switch, so this is safe to
  /// call every time; it never throws, since a failed email must not break
  /// the screen.
  Future<void> emailMe(
    String kind, [
    Map<String, Object> params = const {},
  ]) async {
    try {
      await supa.functions.invoke(
        'send-notification',
        body: {'kind': kind, 'params': params},
      );
    } catch (_) {
      // ignored on purpose
    }
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

  /// Deletes the signed-in user's own account after checking their password
  /// (as the web app does): their uploaded floor plans, saved design files and
  /// picture first, then the account itself, which takes every database row of
  /// theirs with it.
  Future<void> deleteMyAccount({
    required String email,
    required String password,
  }) async {
    final AuthResponse signIn;
    try {
      signIn = await supa.auth.signInWithPassword(
        email: email,
        password: password,
      );
    } on AuthException {
      throw const AuthException('The password is not correct.');
    }
    final userId = signIn.user?.id;
    if (userId == null) {
      throw const AuthException('The password is not correct.');
    }

    for (final bucket in const ['floorplans', 'designs', 'avatars']) {
      final files = await _listFiles(bucket, userId);
      for (var i = 0; i < files.length; i += 100) {
        await supa.storage
            .from(bucket)
            .remove(files.sublist(i, math.min(i + 100, files.length)));
      }
    }
    await supa.rpc('delete_my_account');
    await supa.auth.signOut();
  }

  /// Every file under a folder of a bucket, at any depth.
  Future<List<String>> _listFiles(String bucket, String folder) async {
    final entries = await supa.storage
        .from(bucket)
        .list(path: folder, searchOptions: const SearchOptions(limit: 1000));
    final files = <String>[];
    for (final entry in entries) {
      final path = '$folder/${entry.name}';
      // folders come back without an id
      if (entry.id != null) {
        files.add(path);
      } else {
        files.addAll(await _listFiles(bucket, path));
      }
    }
    return files;
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

  /// The uploaded image's bytes, for sending to the wall detector.
  Future<Uint8List> downloadFloorPlanImage(String path) =>
      supa.storage.from(SupabaseEnv.floorPlansBucket).download(path);

  /// Runs the wall detector on [floorPlan]'s image and stores the result the
  /// way the web app does: a `FloorPlanAnalysis` row (`Detected`) and the
  /// floor plan marked `Analysed`, which the database copies into the room and
  /// structural-element tables. Returns the stored analysis.
  Future<FloorPlanAnalysisRecord> runDetection(
    FloorPlanRecord floorPlan,
  ) async {
    final user = supa.auth.currentUser;
    if (user == null) {
      throw const LayoutServiceException(
        'Your session expired. Please sign in again.',
      );
    }
    final bytes = await downloadFloorPlanImage(floorPlan.imagePath);
    final name = floorPlan.imagePath.split('/').last;
    final detection = await DetectorService.instance.detect(
      bytes: bytes,
      fileName: name,
      floorPlanId: floorPlan.floorPlanId,
    );
    final row = await supa
        .from('FloorPlanAnalysis')
        .upsert({
          'FloorPlanID': floorPlan.floorPlanId,
          'UserID': user.id,
          'DetectionJSON': detection,
          'Status': 'Detected',
          'UpdatedAt': DateTime.now().toUtc().toIso8601String(),
        }, onConflict: 'FloorPlanID')
        .select()
        .single();
    await supa
        .from('FloorPlan')
        .update({'Status': 'Analysed'})
        .eq('FloorPlanID', floorPlan.floorPlanId)
        .eq('UserID', user.id);
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

extension GeneratedLayoutPersistence on FloorPlanRepository {
  /// Saves the layouts the app generated for [roomId] as the analysis row's
  /// `LayoutJSON`, in the shape the web app writes. Any earlier confirmed
  /// layout is cleared, since it belonged to a previous generation.
  Future<void> saveGeneratedLayouts({
    required String floorPlanId,
    required String roomId,
    required Map<String, dynamic> layouts,
  }) {
    final userId = AuthService.instance.currentUser?.id;
    if (userId == null) {
      throw const AuthException('Your session expired. Please sign in again.');
    }
    return supa
        .from('FloorPlanAnalysis')
        .update({
          'SelectedRoomID': roomId,
          'LayoutJSON': {...layouts, 'roomId': roomId},
          'SelectedLayoutJSON': null,
          'Status': 'LayoutReady',
          'UpdatedAt': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('FloorPlanID', floorPlanId)
        .eq('UserID', userId);
  }
}

/// The profile picture: the image lives in the public `avatars` bucket under
/// `<user id>/`, and the `User` row keeps its public address (`AvatarUrl`).
/// Mirrors the web's `avatar.ts`.
class AvatarRepository {
  AvatarRepository._();
  static final AvatarRepository instance = AvatarRepository._();

  static const _bucket = 'avatars';

  /// Stores a new profile picture, records its address on the user's row and
  /// returns it. [bytes] should already be scaled down ([shrinkAvatar]).
  Future<String> upload({
    required String userId,
    required Uint8List bytes,
    required String contentType,
  }) async {
    // A new name every time, so a stale cached picture is never shown.
    final path =
        '$userId/avatar-${DateTime.now().millisecondsSinceEpoch}.'
        '${avatarExtension(contentType)}';
    final storage = supa.storage.from(_bucket);
    await storage.uploadBinary(
      path,
      bytes,
      fileOptions: FileOptions(
        contentType: contentType,
        cacheControl: '31536000',
      ),
    );

    final url = storage.getPublicUrl(path);
    try {
      await supa.from('User').update({'AvatarUrl': url}).eq('UserID', userId);
    } catch (_) {
      await storage.remove([path]);
      rethrow;
    }
    await _removeOldPictures(userId, keep: path);
    return url;
  }

  /// Removes the picture, going back to the user's initials.
  Future<void> remove(String userId) async {
    await supa.from('User').update({'AvatarUrl': null}).eq('UserID', userId);
    await _removeOldPictures(userId);
  }

  /// Deletes every picture of the user's except [keep]. Leftover files are
  /// harmless, so a failure here is not worth failing the change over.
  Future<void> _removeOldPictures(String userId, {String? keep}) async {
    try {
      final storage = supa.storage.from(_bucket);
      final files = await storage.list(path: userId);
      final stale = [
        for (final f in files)
          if ('$userId/${f.name}' != keep) '$userId/${f.name}',
      ];
      if (stale.isNotEmpty) await storage.remove(stale);
    } catch (_) {}
  }
}

class SavedDesignRepository {
  SavedDesignRepository._();
  static final SavedDesignRepository instance = SavedDesignRepository._();

  /// Keeps one furnished room as a saved design (the web's dashboard lists
  /// these). Saving the same room and layout again replaces the earlier copy.
  Future<void> save({
    required String floorPlanId,
    required String roomId,
    required String roomName,
    required AnalysisLayout layout,
  }) async {
    final user = supa.auth.currentUser;
    if (user == null) {
      throw const LayoutServiceException(
        'Your session expired. Please sign in again.',
      );
    }
    await supa.from('SavedDesign').upsert({
      'UserID': user.id,
      'FloorPlanID': floorPlanId,
      'RoomID': roomId,
      'RoomName': roomName,
      'LayoutType': layout.type,
      'Title': layout.title,
      'Score': layout.score,
      'LayoutJSON': layout.raw,
      'UpdatedAt': DateTime.now().toUtc().toIso8601String(),
    }, onConflict: 'FloorPlanID,RoomID,LayoutType');
  }

  static const _bucket = 'designs';
  static const _previewLinkSeconds = 60 * 60;

  /// The user's saved designs, newest first, as the web's
  /// `listSavedDesigns` returns them: preview pictures get a short-lived
  /// link, since the bucket is private.
  Future<List<SavedDesignRecord>> list(String userId) async {
    final rows = await supa
        .from('SavedDesign')
        .select(
          'DesignID, FloorPlanID, RoomID, RoomName, Title, Score, '
          'LayoutJSON, ModelPath, PreviewPath, UpdatedAt',
        )
        .eq('UserID', userId)
        .order('UpdatedAt', ascending: false);

    final paths = [
      for (final row in rows)
        if (row['PreviewPath'] case final String path) path,
    ];
    final links = <String, String>{};
    if (paths.isNotEmpty) {
      try {
        final signed = await supa.storage
            .from(_bucket)
            .createSignedUrlsResult(paths, _previewLinkSeconds);
        for (final s in signed.whereType<SignedUrlSuccess>()) {
          links[s.path] = s.signedUrl;
        }
      } catch (_) {
        // a design without its picture still lists
      }
    }

    return [
      for (final row in rows)
        SavedDesignRecord.fromJson(row, previewUrl: links[row['PreviewPath']]),
    ];
  }

  /// Removes a saved design and its files, as the web's `deleteSavedDesign`.
  Future<void> delete(SavedDesignRecord design) async {
    final files = design.storagePaths;
    if (files.isNotEmpty) await supa.storage.from(_bucket).remove(files);
    await supa.from('SavedDesign').delete().eq('DesignID', design.designId);
  }
}

/// The totals on the welcome screen. They come from a database function that
/// anyone, signed in or not, may call: it counts rows and returns nothing
/// about any one of them.
class SiteStatsRepository {
  SiteStatsRepository._();
  static final SiteStatsRepository instance = SiteStatsRepository._();

  /// The live totals, or null if they can't be read, so the screen shows
  /// dashes rather than an error.
  Future<SiteStats?> fetch() async {
    try {
      return SiteStats.fromRpc(await supa.rpc('get_site_stats'));
    } catch (_) {
      return null;
    }
  }
}

class AdminRepository {
  AdminRepository._();
  static final AdminRepository instance = AdminRepository._();

  /// How many people will get product news: those with the "Product news"
  /// switch on (the web's `countNewsReaders`).
  Future<int> countNewsReaders() => supa
      .from('User')
      .count()
      .filter('NotificationPrefs->>updates', 'eq', 'true');

  /// Emails a product-news message to everyone who wants it, or, with
  /// [testOnly], to the admin's own address alone. Returns how many people it
  /// went to; throws an [Exception] saying what went wrong, in words from
  /// [newsProblem].
  Future<int> sendProductNews({
    required String subject,
    required String message,
    bool testOnly = false,
  }) async {
    final Object? body;
    try {
      final response = await supa.functions.invoke(
        'send-notification',
        body: {
          'kind': 'news',
          'params': {
            'subject': subject,
            'message': message,
            'testOnly': testOnly,
          },
        },
      );
      body = response.data;
    } on FunctionException catch (e) {
      final details = e.details;
      final reason = details is Map
          ? '${details['reason'] ?? details['error'] ?? ''}'
          : '';
      throw Exception(newsProblem(reason));
    }
    if (body is Map && body['sent'] == false) {
      throw Exception(newsProblem('${body['reason'] ?? ''}'));
    }
    return body is Map && body['recipients'] is num
        ? (body['recipients'] as num).toInt()
        : 0;
  }

  Future<List<AdminUserRecord>> fetchUsers() async {
    final rows = await supa
        .from('User')
        .select('UserID, UserName, FullName, Email, LastSignIn, Role')
        .order('FullName', ascending: true);
    return rows.map(AdminUserRecord.fromJson).toList();
  }

  /// What admins did, newest first (`AdminAuditLog`; admins can read it).
  Future<List<AuditEntry>> fetchAuditLog({int limit = 100}) async {
    final rows = await supa
        .from('AdminAuditLog')
        .select()
        .order('CreatedAt', ascending: false)
        .limit(limit);
    return rows.map(AuditEntry.fromJson).toList();
  }

  /// Permanently deletes a customer's account (SRS UC3). The `delete-user`
  /// edge function checks the caller is an admin, refuses admin accounts and
  /// the caller's own, removes the user's files and the auth user (the
  /// database rows go with it) and writes the audit-log line.
  Future<void> deleteAccount(String userId) async {
    final response = await supa.functions.invoke(
      'delete-user',
      body: {'userId': userId},
    );
    if (response.status != 200) {
      final error = (response.data is Map)
          ? (response.data as Map)['error']
          : null;
      throw Exception(error?.toString() ?? 'The account could not be deleted.');
    }
  }
}
