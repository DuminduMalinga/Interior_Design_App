import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

/// The room types that have a rule-based layout engine on the web backend
/// (`Interior-Design-Web/backend/<room>_layout`).
///
/// Rooms are integrated into the mobile app one at a time; [kindsSupported]
/// lists the ones wired up so far.
enum RoomKind {
  living,
  bathroom,
  bedroom,
  masterBedroom,
  kitchen,
  dining;

  /// Which layout engine a room gets, from its OCR'd name; null when none.
  /// Mirrors the web's `roomKind.ts`, including its ordering: an en-suite
  /// ("Bedroom 1 Bath") gets the bathroom engine.
  static RoomKind? fromName(String name) {
    if (RegExp('living', caseSensitive: false).hasMatch(name)) return living;
    if (RegExp(
      r'bath|toilet|w\.?c|wash\s*room|shower|rest\s*room|lavatory',
      caseSensitive: false,
    ).hasMatch(name)) {
      return bathroom;
    }
    if (RegExp('bed', caseSensitive: false).hasMatch(name)) {
      return RegExp(
            r'master|primary|main|\bm\.?\s*bed',
            caseSensitive: false,
          ).hasMatch(name)
          ? masterBedroom
          : bedroom;
    }
    if (RegExp('kitchen', caseSensitive: false).hasMatch(name)) return kitchen;
    if (RegExp('din', caseSensitive: false).hasMatch(name)) return dining;
    return null;
  }

  /// Room kinds whose layout service the app can call.
  static const Set<RoomKind> kindsSupported = {
    living,
    bedroom,
    masterBedroom,
    kitchen,
  };

  bool get isSupported => kindsSupported.contains(this);

  String get label => switch (this) {
    living => 'living room',
    bathroom => 'bathroom',
    bedroom => 'bedroom',
    masterBedroom => 'master bedroom',
    kitchen => 'kitchen',
    dining => 'dining area',
  };
}

/// Where the layout services run. Override at build time, e.g.
/// `--dart-define=LAYOUT_SERVICE_BASE=https://my-host` to use the Caddy
/// deployment (one hostname, a path per service), or set an individual
/// `--dart-define=LIVING_ROOM_LAYOUT_URL=...`.
///
/// The defaults address a service run locally with `uvicorn`; `10.0.2.2` is
/// the Android emulator's alias for the host machine's `localhost`.
class LayoutServiceEnv {
  const LayoutServiceEnv._();

  static const String _base = String.fromEnvironment('LAYOUT_SERVICE_BASE');
  static const String _livingRoom = String.fromEnvironment(
    'LIVING_ROOM_LAYOUT_URL',
  );

  static const String _bedroom = String.fromEnvironment('BEDROOM_LAYOUT_URL');

  static const String _masterBedroom = String.fromEnvironment(
    'MASTER_BEDROOM_LAYOUT_URL',
  );

  static const String _kitchen = String.fromEnvironment('KITCHEN_LAYOUT_URL');

  static String get livingRoomUrl => _resolve(
    _livingRoom,
    path: 'living-room',
    localDefault: 'http://10.0.2.2:8100',
  );

  static String get bedroomUrl =>
      _resolve(_bedroom, path: 'bedroom', localDefault: 'http://10.0.2.2:8200');

  static String get masterBedroomUrl => _resolve(
    _masterBedroom,
    path: 'master-bedroom',
    localDefault: 'http://10.0.2.2:8600',
  );

  static String get kitchenUrl =>
      _resolve(_kitchen, path: 'kitchen', localDefault: 'http://10.0.2.2:8300');

  static String urlFor(RoomKind kind) => switch (kind) {
    RoomKind.living => livingRoomUrl,
    RoomKind.bedroom => bedroomUrl,
    RoomKind.masterBedroom => masterBedroomUrl,
    RoomKind.kitchen => kitchenUrl,
    _ => throw UnsupportedError('No layout service wired for ${kind.name}.'),
  };

  static String _resolve(
    String explicit, {
    required String path,
    required String localDefault,
  }) {
    final url = explicit.isNotEmpty
        ? explicit
        : _base.isNotEmpty
        ? '$_base/$path'
        : localDefault;
    return url.endsWith('/') ? url.substring(0, url.length - 1) : url;
  }
}

/// A failure the user can act on (service down, session expired, bad room).
class LayoutServiceException implements Exception {
  const LayoutServiceException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// What the household does in a living room (rule 7 of the engine).
enum LivingActivity { conversation, tv, reading, work, dining }

/// Planning options for a living room; the engine assumes them from the room
/// when [activities] is null.
class LivingRoomOptions {
  const LivingRoomOptions({this.activities, this.accessible = false});

  final List<LivingActivity>? activities;

  /// An occupant has mobility needs: wider paths, turning space, no loose rug.
  final bool accessible;

  Map<String, dynamic> toJson() => {
    if (activities != null) 'activities': [for (final a in activities!) a.name],
    'accessible': accessible,
  };
}

/// Planning options for a bedroom or master bedroom: the head count. Left
/// null, the engine infers it (a bedroom from the floor area, a master
/// bedroom two).
class BedroomOptions {
  const BedroomOptions({this.occupants});

  /// 1 or 2.
  final int? occupants;

  Map<String, dynamic> toJson() => {
    if (occupants != null) 'occupants': occupants,
  };
}

/// Planning options for a kitchen: whether to try a dining table. Left null,
/// the engine decides from the floor area.
class KitchenOptions {
  const KitchenOptions({this.diningTable});

  final bool? diningTable;

  Map<String, dynamic> toJson() => {
    if (diningTable != null) 'dining_table': diningTable,
  };
}

/// The wall detector's output for one floor plan, as stored in
/// `FloorPlanAnalysis.DetectionJSON`, from which a layout request is built.
class DetectionDocument {
  const DetectionDocument(this._json);

  /// Returns null when [detectionJson] is not a detection document.
  static DetectionDocument? from(Object? detectionJson) => detectionJson is Map
      ? DetectionDocument(Map<String, dynamic>.from(detectionJson))
      : null;

  final Map<String, dynamic> _json;

  Map<String, dynamic>? roomJson(String roomId) {
    final rooms = _json['rooms'];
    if (rooms is! List) return null;
    for (final r in rooms) {
      if (r is Map && r['id']?.toString() == roomId) {
        return Map<String, dynamic>.from(r);
      }
    }
    return null;
  }

  /// The body the layout services take: the room, every door and window on
  /// the plan, and every room (so the engine can tell which door leads where).
  Map<String, dynamic>? requestFor(String roomId) {
    final room = roomJson(roomId);
    if (room == null || room['bbox'] is! Map) return null;

    final widthM = _num(room['widthM']);
    final heightM = _num(room['heightM']);
    final scaleMmPerPx = _num(_json['scaleMmPerPx']);
    final hasPrintedSize =
        _num(room['labelWidthM']) != null &&
        _num(room['labelHeightM']) != null &&
        widthM != null &&
        heightM != null;

    final detections = _json['detections'];
    final rooms = _json['rooms'];
    return {
      'room': {
        'id': room['id'].toString(),
        'name': room['name'],
        'bbox': room['bbox'],
        // The outline traced from the walls, so an L-shaped room is
        // furnished as an L.
        if (room['shapeSource'] == 'walls' && room['polygon'] != null)
          'polygon': room['polygon'],
        // The size printed on the plan, so the layout is planned at the size
        // the room list shows.
        if (hasPrintedSize) 'width_m': widthM,
        if (hasPrintedSize) 'length_m': heightM,
      },
      'detections': [
        if (detections is List)
          for (final d in detections)
            if (d is Map && (d['class'] == 'Door' || d['class'] == 'Window'))
              {'id': d['id'], 'class': d['class'], 'bbox': d['bbox']},
      ],
      'rooms': [
        if (rooms is List)
          for (final r in rooms)
            if (r is Map) {'id': r['id'], 'name': r['name'], 'bbox': r['bbox']},
      ],
      if (scaleMmPerPx != null) 'scale_m_per_px': scaleMmPerPx / 1000,
    };
  }

  static double? _num(Object? v) => v is num ? v.toDouble() : null;
}

/// Calls the web backend's layout services as the signed-in user.
class LayoutService {
  LayoutService({http.Client? client}) : _client = client ?? http.Client();

  static final LayoutService instance = LayoutService();

  final http.Client _client;

  /// Every layout the room allows, best first, each scored against the
  /// engine's rules. The result has the shape of `LayoutJSON` minus the
  /// `roomId` (added by the caller when saving).
  Future<Map<String, dynamic>> generateAll({
    required RoomKind kind,
    required Map<String, dynamic> request,
    Map<String, dynamic> options = const {},
  }) async {
    final baseUrl = LayoutServiceEnv.urlFor(kind);
    final token = Supabase.instance.client.auth.currentSession?.accessToken;
    if (token == null) {
      throw const LayoutServiceException(
        'Your session expired. Please sign in again.',
      );
    }

    final http.Response response;
    try {
      response = await _client
          .post(
            Uri.parse('$baseUrl/generate-all'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({...request, ...options}),
          )
          .timeout(const Duration(seconds: 60));
    } on TimeoutException {
      throw LayoutServiceException(
        'The ${kind.label} layout service took too long to answer.',
      );
    } catch (_) {
      throw LayoutServiceException(
        'Could not reach the ${kind.label} layout service at $baseUrl. '
        'Is it running?',
      );
    }

    final body = _decode(response);
    if (response.statusCode != 200) {
      final detail = body is Map ? body['detail'] : null;
      throw LayoutServiceException(
        'Layout generation failed: '
        '${detail ?? '${response.statusCode} ${response.reasonPhrase}'}',
      );
    }
    if (body is! Map) {
      throw const LayoutServiceException(
        'The layout service sent an unreadable answer.',
      );
    }
    return Map<String, dynamic>.from(body);
  }

  static Object? _decode(http.Response response) {
    try {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } catch (_) {
      return null;
    }
  }
}
