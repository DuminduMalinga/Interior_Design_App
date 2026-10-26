/// Plain data models mirroring the `public` schema tables in Supabase.
///
/// Column names are kept in their original PascalCase to match the
/// database exactly (the project's tables were not created by this app and
/// must not be altered), while Dart-side field names stay idiomatic
/// camelCase.
library;

import 'dart:ui' show Offset, Rect;

import 'plan_geometry.dart';

/// What the user chose to be emailed about (`User.NotificationPrefs`, shared
/// with the web app).
class NotificationPrefs {
  const NotificationPrefs({
    this.email = true,
    this.browser = false,
    this.updates = true,
  });

  factory NotificationPrefs.fromJson(Object? json) {
    if (json is! Map) return const NotificationPrefs();
    return NotificationPrefs(
      email: json['email'] != false,
      browser: json['browser'] == true,
      updates: json['updates'] != false,
    );
  }

  /// "Plan ready" and "design saved" emails.
  final bool email;

  /// Browser alerts; only the web app shows them, the app keeps the choice.
  final bool browser;

  /// Product news from the admins.
  final bool updates;

  NotificationPrefs copyWith({bool? email, bool? updates}) => NotificationPrefs(
    email: email ?? this.email,
    browser: browser,
    updates: updates ?? this.updates,
  );

  Map<String, dynamic> toJson() => {
    'email': email,
    'browser': browser,
    'updates': updates,
  };
}

class AppUserProfile {
  const AppUserProfile({
    required this.userId,
    required this.email,
    required this.fullName,
    required this.userName,
    required this.role,
    this.bio,
    this.location,
    this.phone,
    this.avatarUrl,
    this.lastSignIn,
    this.notifications = const NotificationPrefs(),
  });

  factory AppUserProfile.fromJson(Map<String, dynamic> json) => AppUserProfile(
    userId: json['UserID'] as String,
    email: json['Email'] as String,
    fullName: json['FullName'] as String,
    userName: json['UserName'] as String,
    role: json['Role'] as String? ?? 'User',
    bio: json['Bio'] as String?,
    location: json['Location'] as String?,
    phone: json['Phone'] as String?,
    avatarUrl: json['AvatarUrl'] as String?,
    notifications: NotificationPrefs.fromJson(json['NotificationPrefs']),
    lastSignIn: json['LastSignIn'] == null
        ? null
        : DateTime.tryParse(json['LastSignIn'] as String),
  );

  final String userId;
  final String email;
  final String fullName;
  final String userName;
  final String role;
  final String? bio;
  final String? location;
  final String? phone;

  /// Public address of the profile picture in the `avatars` bucket; null
  /// shows the [initials] instead.
  final String? avatarUrl;
  final DateTime? lastSignIn;
  final NotificationPrefs notifications;

  bool get isAdmin => role.toLowerCase() == 'admin';

  String get initials {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }
}

class FloorPlanRecord {
  const FloorPlanRecord({
    required this.floorPlanId,
    required this.userId,
    required this.imagePath,
    required this.status,
    required this.uploadDateTime,
  });

  factory FloorPlanRecord.fromJson(Map<String, dynamic> json) =>
      FloorPlanRecord(
        floorPlanId: json['FloorPlanID'] as String,
        userId: json['UserID'] as String,
        imagePath: json['ImagePath'] as String,
        status: json['Status'] as String? ?? 'Uploaded',
        uploadDateTime: DateTime.parse(json['UploadDateTime'] as String),
      );

  final String floorPlanId;
  final String userId;
  final String imagePath;
  final String status;
  final DateTime uploadDateTime;

  /// Derives a human-friendly title since the table has no name column.
  String get displayTitle {
    final base = imagePath.split('/').last.split('.').first;
    final cleaned = base.replaceAll(RegExp(r'[_-]'), ' ').trim();
    if (cleaned.isEmpty) return 'Floor plan';
    return cleaned
        .split(' ')
        .map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1))
        .join(' ');
  }
}

class FloorPlanAnalysisRecord {
  const FloorPlanAnalysisRecord({
    required this.floorPlanId,
    required this.userId,
    required this.detectionJson,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.layoutJson,
    this.selectedLayoutJson,
    this.selectedRoomId,
  });

  factory FloorPlanAnalysisRecord.fromJson(Map<String, dynamic> json) =>
      FloorPlanAnalysisRecord(
        floorPlanId: json['FloorPlanID'] as String,
        userId: json['UserID'] as String,
        detectionJson: json['DetectionJSON'],
        layoutJson: json['LayoutJSON'],
        selectedLayoutJson: json['SelectedLayoutJSON'],
        selectedRoomId: json['SelectedRoomID'] as String?,
        status: json['Status'] as String? ?? 'Processing',
        createdAt: DateTime.parse(json['CreatedAt'] as String),
        updatedAt: DateTime.parse(json['UpdatedAt'] as String),
      );

  final String floorPlanId;
  final String userId;
  final dynamic detectionJson;
  final dynamic layoutJson;
  final dynamic selectedLayoutJson;
  final String? selectedRoomId;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// The web pipeline reports `Detected` -> `LayoutReady` -> `LayoutSelected`;
  /// `Completed` is kept for the older relational pipeline. Any of them means
  /// rooms can be read.
  bool get isComplete => const {
    'detected',
    'layoutready',
    'layoutselected',
    'completed',
  }.contains(status.toLowerCase());
  bool get isFailed => status.toLowerCase() == 'failed';

  List<AnalysisRoom> get rooms => AnalysisRoom.listFrom(detectionJson);

  /// The detection with the plan image's size, counts and size scale.
  AnalysisPlan get plan => AnalysisPlan.from(detectionJson);
}

class RoomRecord {
  const RoomRecord({
    required this.roomId,
    required this.floorPlanId,
    required this.roomType,
    required this.length,
    required this.width,
  });

  factory RoomRecord.fromJson(Map<String, dynamic> json) => RoomRecord(
    roomId: json['RoomID'] as String,
    floorPlanId: json['FloorPlanID'] as String,
    roomType: json['RoomType'] as String,
    length: (json['Length'] as num).toDouble(),
    width: (json['Width'] as num).toDouble(),
  );

  final String roomId;
  final String floorPlanId;
  final String roomType;
  final double length;
  final double width;

  double get area => length * width;
}

class StructuralElementRecord {
  const StructuralElementRecord({
    required this.elementNo,
    required this.roomId,
    required this.elementType,
    this.position,
    this.size,
    this.orientation,
  });

  factory StructuralElementRecord.fromJson(Map<String, dynamic> json) =>
      StructuralElementRecord(
        elementNo: json['ElementNo'] as String,
        roomId: json['RoomID'] as String,
        elementType: json['ElementType'] as String,
        position: json['Position'] as String?,
        size: json['Size'] == null ? null : (json['Size'] as num).toDouble(),
        orientation: json['Orientation'] == null
            ? null
            : (json['Orientation'] as num).toDouble(),
      );

  final String elementNo;
  final String roomId;
  final String elementType;
  final String? position;
  final double? size;
  final double? orientation;
}

class LayoutRecord {
  const LayoutRecord({
    required this.layoutId,
    required this.roomId,
    required this.score,
    required this.generateDateTime,
  });

  factory LayoutRecord.fromJson(Map<String, dynamic> json) => LayoutRecord(
    layoutId: json['LayoutID'] as String,
    roomId: json['RoomID'] as String,
    score: (json['Score'] as num).toDouble(),
    generateDateTime: DateTime.parse(json['GenerateDateTime'] as String),
  );

  final String layoutId;
  final String roomId;
  final double score;
  final DateTime generateDateTime;
}

class FurnitureRecord {
  const FurnitureRecord({
    required this.furnitureId,
    required this.furnitureName,
    this.category,
    this.length,
    this.width,
  });

  factory FurnitureRecord.fromJson(Map<String, dynamic> json) =>
      FurnitureRecord(
        furnitureId: json['FurnitureID'] as String,
        furnitureName: json['FurnitureName'] as String,
        category: json['Category'] as String?,
        length: json['Length'] == null
            ? null
            : (json['Length'] as num).toDouble(),
        width: json['Width'] == null ? null : (json['Width'] as num).toDouble(),
      );

  final String furnitureId;
  final String furnitureName;
  final String? category;
  final double? length;
  final double? width;
}

class FurnitureLayoutRecord {
  const FurnitureLayoutRecord({
    required this.furnitureLayoutId,
    required this.layoutId,
    this.positionX,
    this.positionY,
    this.rotation,
  });

  factory FurnitureLayoutRecord.fromJson(Map<String, dynamic> json) =>
      FurnitureLayoutRecord(
        furnitureLayoutId: json['FurnitureLayoutID'] as String,
        layoutId: json['LayoutID'] as String,
        positionX: json['PositionX'] == null
            ? null
            : (json['PositionX'] as num).toDouble(),
        positionY: json['PositionY'] == null
            ? null
            : (json['PositionY'] as num).toDouble(),
        rotation: json['Rotation'] == null
            ? null
            : (json['Rotation'] as num).toDouble(),
      );

  final String furnitureLayoutId;
  final String layoutId;
  final double? positionX;
  final double? positionY;
  final double? rotation;
}

/// A [FurnitureLayoutRecord] joined with its [FurnitureRecord] through
/// `Furniture_FurnitureLayout`, ready for rendering.
class PlacedFurniture {
  const PlacedFurniture({required this.placement, required this.furniture});

  final FurnitureLayoutRecord placement;
  final FurnitureRecord furniture;
}

/// A row of the `User` table as the admin account list shows it.
class AdminUserRecord {
  const AdminUserRecord({
    required this.userId,
    required this.fullName,
    required this.userName,
    required this.email,
    required this.role,
    this.lastSignIn,
    this.avatarUrl,
  });

  factory AdminUserRecord.fromJson(Map<String, dynamic> json) {
    final email = json['Email'] as String? ?? '';
    final userName = (json['UserName'] as String?)?.trim();
    return AdminUserRecord(
      userId: json['UserID'] as String,
      fullName: (json['FullName'] as String?)?.trim() ?? '',
      userName: (userName != null && userName.isNotEmpty)
          ? userName
          : (email.contains('@') ? email.split('@').first : email),
      email: email,
      role: json['Role'] as String? ?? 'Customer',
      lastSignIn: json['LastSignIn'] == null
          ? null
          : DateTime.tryParse(json['LastSignIn'] as String),
      avatarUrl: (json['AvatarUrl'] as String?)?.trim().isNotEmpty == true
          ? (json['AvatarUrl'] as String).trim()
          : null,
    );
  }

  final String userId;
  final String fullName;
  final String userName;
  final String email;
  final String role;
  final DateTime? lastSignIn;

  /// The account's profile picture, if it has set one.
  final String? avatarUrl;

  bool get isAdmin => role.trim().toLowerCase() == 'admin';
  String get displayName => fullName.isNotEmpty ? fullName : userName;

  String get initials {
    final parts = displayName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }
}

/// One line of `AdminAuditLog`: what an admin did, written by the
/// `delete-user` edge function.
class AuditEntry {
  const AuditEntry({
    required this.action,
    required this.createdAt,
    this.actorId,
    this.targetId,
    this.detail = const {},
  });

  factory AuditEntry.fromJson(Map<String, dynamic> json) => AuditEntry(
    action: json['Action'] as String? ?? 'unknown',
    createdAt: DateTime.parse(json['CreatedAt'] as String),
    actorId: json['ActorID'] as String?,
    targetId: json['TargetID'] as String?,
    detail: json['Detail'] is Map
        ? Map<String, dynamic>.from(json['Detail'] as Map)
        : const {},
  );

  final String action;
  final DateTime createdAt;
  final String? actorId;
  final String? targetId;
  final Map<String, dynamic> detail;

  /// "delete_user" -> "Delete user".
  String get label {
    final words = action.replaceAll('_', ' ').trim();
    return words.isEmpty
        ? 'Unknown'
        : words[0].toUpperCase() + words.substring(1);
  }

  /// The detail as short `key: value` text, e.g. the deleted user's email.
  String get summary => [
    for (final e in detail.entries)
      if (e.value != null && '${e.value}'.isNotEmpty) '${e.key}: ${e.value}',
  ].join(' · ');
}

// ---------------------------------------------------------------------------
// Web-pipeline analysis JSON
//
// The web app does not write the relational Room/Layout tables. It stores the
// wall-detector output in `FloorPlanAnalysis.DetectionJSON` and the layout
// engine output in `LayoutJSON` / `SelectedLayoutJSON`, so the mobile app
// reads those documents (units: millimetres, origin bottom-left, y up).
// ---------------------------------------------------------------------------

double? _asDouble(Object? v) => v is num ? v.toDouble() : null;

/// A room entry from `DetectionJSON.rooms`.
class AnalysisRoom {
  const AnalysisRoom({
    required this.id,
    required this.name,
    required this.confidence,
    required this.labelDetected,
    this.widthM,
    this.heightM,
    this.areaM2,
    this.bboxFraction,
    this.polygonFraction,
    this.areaSource,
    this.widthPx,
    this.heightPx,
    this.areaPx,
  });

  factory AnalysisRoom.fromJson(Map<String, dynamic> json) {
    final pct = json['bboxPct'];
    Rect? bounds;
    if (pct is Map) {
      final x = _asDouble(pct['x']);
      final y = _asDouble(pct['y']);
      final w = _asDouble(pct['w']);
      final h = _asDouble(pct['h']);
      if (x != null && y != null && w != null && h != null) {
        bounds = Rect.fromLTWH(x / 100, y / 100, w / 100, h / 100);
      }
    }
    final name = (json['name'] as String?)?.trim();
    return AnalysisRoom(
      id: json['id'].toString(),
      name: (name != null && name.isNotEmpty)
          ? name
          : (json['fallbackName'] as String? ?? 'Room'),
      confidence: _asDouble(json['confidence']) ?? 0,
      labelDetected: json['labelDetected'] == true,
      widthM: _asDouble(json['widthM']),
      heightM: _asDouble(json['heightM']),
      areaM2: _asDouble(json['areaM2']),
      bboxFraction: bounds,
      polygonFraction: _pctPoints(json['polygonPct']),
      areaSource: json['areaSource'] as String?,
      widthPx: _asDouble(json['widthPx']),
      heightPx: _asDouble(json['heightPx']),
      areaPx: _asDouble(json['areaPx']),
    );
  }

  /// Rooms from a `DetectionJSON` document; empty if it has none.
  static List<AnalysisRoom> listFrom(Object? detectionJson) {
    if (detectionJson is! Map) return const [];
    final rooms = detectionJson['rooms'];
    if (rooms is! List) return const [];
    return [
      for (final r in rooms)
        if (r is Map) AnalysisRoom.fromJson(Map<String, dynamic>.from(r)),
    ];
  }

  final String id;
  final String name;
  final double confidence;
  final bool labelDetected;
  final double? widthM;
  final double? heightM;
  final double? areaM2;

  /// Position within the plan image as fractions (0-1) of its size.
  final Rect? bboxFraction;

  /// The room's own outline, traced from the walls, as fractions (0-1) of the
  /// plan image; null on detections saved before outlines were traced.
  final List<Offset>? polygonFraction;

  /// Where the size came from: "ocr" (printed on the plan), "estimated"
  /// (from the plan's scale), or null when there is no size.
  final String? areaSource;
  final double? widthPx;
  final double? heightPx;
  final double? areaPx;

  /// Where the room is on the plan: its outline, else its box's corners.
  /// Null when the detection recorded no position at all.
  List<Offset>? get outline =>
      polygonFraction ??
      (bboxFraction == null ? null : rectCorners(bboxFraction!));

  bool get isLivingRoom =>
      RegExp('living', caseSensitive: false).hasMatch(name);
}

/// Reads `[[x, y], …]` in percent into fractions; null unless it is a real
/// outline (three or more points).
List<Offset>? _pctPoints(Object? value) {
  if (value is! List) return null;
  final points = <Offset>[];
  for (final p in value) {
    if (p is! List || p.length < 2) return null;
    final x = _asDouble(p[0]);
    final y = _asDouble(p[1]);
    if (x == null || y == null) return null;
    points.add(Offset(x / 100, y / 100));
  }
  return points.length >= 3 ? points : null;
}

/// A room's size in metres and where it came from, as the web's room list
/// shows it.
class RoomSize {
  const RoomSize({
    required this.widthM,
    required this.heightM,
    required this.areaM2,
    required this.source,
  });

  final double widthM;
  final double heightM;
  final double areaM2;

  /// "ocr", "estimated", "door" or "default"; null when not recorded.
  final String? source;

  /// "4.20 × 3.10 m", as the web writes it.
  String get dims =>
      '${widthM.toStringAsFixed(2)} × ${heightM.toStringAsFixed(2)} m';

  String get area => '${areaM2.toStringAsFixed(1)} m²';

  /// How trustworthy the size is: the web's `SIZE_NOTES`.
  String? get note => switch (source) {
    'ocr' => "from the plan's printed area",
    'estimated' => "estimated from the plan's scale",
    'door' => 'estimated from the doors, taking a standard 900 mm door',
    'default' => 'a rough estimate: the plan has no scale and no doors',
    _ => null,
  };
}

/// The whole of a `DetectionJSON` document the room-selection screen needs:
/// its rooms, the plan image's size and the counts of what was found.
class AnalysisPlan {
  const AnalysisPlan({
    required this.rooms,
    required this.imageWidth,
    required this.imageHeight,
    required this.counts,
    required this.mmPerPx,
    required this.scaleSource,
  });

  /// An empty plan for anything that is not a detection document.
  static const empty = AnalysisPlan(
    rooms: [],
    imageWidth: 0,
    imageHeight: 0,
    counts: {},
    mmPerPx: _defaultMmPerPx,
    scaleSource: 'default',
  );

  factory AnalysisPlan.from(Object? detectionJson) {
    if (detectionJson is! Map) return empty;
    final counts = <String, int>{};
    final rawCounts = detectionJson['counts'];
    if (rawCounts is Map) {
      rawCounts.forEach((k, v) {
        if (v is num) counts['$k'] = v.toInt();
      });
    }

    // What the layout engines assume for a plan with no printed areas: a
    // standard door leaf over the median detected door, else a flat default.
    final spans = <double>[];
    final detections = detectionJson['detections'];
    if (detections is List) {
      for (final d in detections) {
        if (d is! Map || d['class'] != 'Door' || d['bbox'] is! Map) continue;
        final b = d['bbox'] as Map;
        final x1 = _asDouble(b['x1']), y1 = _asDouble(b['y1']);
        final x2 = _asDouble(b['x2']), y2 = _asDouble(b['y2']);
        if (x1 == null || y1 == null || x2 == null || y2 == null) continue;
        final span = (x2 - x1) > (y2 - y1) ? x2 - x1 : y2 - y1;
        if (span > 0) spans.add(span);
      }
    }
    spans.sort();

    return AnalysisPlan(
      rooms: AnalysisRoom.listFrom(detectionJson),
      imageWidth: _asDouble(detectionJson['imageWidth']) ?? 0,
      imageHeight: _asDouble(detectionJson['imageHeight']) ?? 0,
      counts: counts,
      mmPerPx: spans.isEmpty
          ? _defaultMmPerPx
          : _standardDoorWidthMm / spans[spans.length ~/ 2],
      scaleSource: spans.isEmpty ? 'default' : 'door',
    );
  }

  static const _standardDoorWidthMm = 900.0;
  static const _defaultMmPerPx = 20.0;

  final List<AnalysisRoom> rooms;
  final double imageWidth;
  final double imageHeight;

  /// What the detector found, by kind: Wall, Room, Door, Window.
  final Map<String, int> counts;

  /// Millimetres per pixel assumed for rooms with no printed size, and what
  /// that assumption rests on ("door" or "default").
  final double mmPerPx;
  final String scaleSource;

  /// Width over height of the plan image; 4:3 when it is not known.
  double get aspectRatio =>
      imageWidth > 0 && imageHeight > 0 ? imageWidth / imageHeight : 4 / 3;

  /// The room's size: the printed one when the plan has it, else an estimate
  /// from the plan's scale; null when the detection holds neither.
  RoomSize? sizeOf(AnalysisRoom room) {
    final w = room.widthM, h = room.heightM, a = room.areaM2;
    if (w != null && h != null && a != null) {
      return RoomSize(
        widthM: w,
        heightM: h,
        areaM2: a,
        source: room.areaSource,
      );
    }
    final wp = room.widthPx, hp = room.heightPx, ap = room.areaPx;
    if (wp == null || hp == null || ap == null) return null;
    final mPerPx = mmPerPx / 1000;
    return RoomSize(
      widthM: wp * mPerPx,
      heightM: hp * mPerPx,
      areaM2: ap * mPerPx * mPerPx,
      source: scaleSource,
    );
  }
}

class AnalysisFurniture {
  const AnalysisFurniture({
    required this.id,
    required this.type,
    required this.x0,
    required this.y0,
    required this.x1,
    required this.y1,
    required this.height,
    this.facing = 'south',
    this.mounted,
    this.mountHeight,
    this.shape,
    this.model,
    this.role,
    this.parts = const [],
    this.engineLabel,
    this.placementStrategy,
    this.reasons = const [],
    this.widthMm,
    this.depthMm,
  });

  /// `bbox` is `[x0, y0, x1, y1]` in mm.
  factory AnalysisFurniture.fromJson(Map<String, dynamic> json) {
    final bbox = json['bbox'];
    double x0, y0, x1, y1;
    if (bbox is List && bbox.length == 4) {
      x0 = _asDouble(bbox[0]) ?? 0;
      y0 = _asDouble(bbox[1]) ?? 0;
      x1 = _asDouble(bbox[2]) ?? 0;
      y1 = _asDouble(bbox[3]) ?? 0;
    } else {
      x0 = _asDouble(json['x']) ?? 0;
      y0 = _asDouble(json['y']) ?? 0;
      x1 = x0 + (_asDouble(json['width']) ?? 0);
      y1 = y0 + (_asDouble(json['depth']) ?? 0);
    }
    return AnalysisFurniture(
      id: json['id'].toString(),
      type: json['type'] as String? ?? 'furniture',
      x0: x0,
      y0: y0,
      x1: x1,
      y1: y1,
      height: _asDouble(json['height']) ?? 700,
      facing: json['facing'] as String? ?? 'south',
      mounted: json['mounted'] as String?,
      mountHeight: _asDouble(json['mount_height']),
      shape: json['shape'] as String?,
      model: json['model']?.toString(),
      role: json['role']?.toString(),
      parts: [
        if (json['parts'] is List)
          for (final part in json['parts'] as List)
            if (part is List && part.length == 4)
              [for (final v in part) _asDouble(v) ?? 0],
      ],
      engineLabel: (json['label'] as String?)?.trim(),
      placementStrategy: (json['placement_strategy'] as String?)?.trim(),
      reasons: [
        if (json['reasons'] is List)
          for (final r in json['reasons'] as List)
            if (r is String && r.trim().isNotEmpty) r.trim(),
      ],
      widthMm: _asDouble(json['width']),
      depthMm: _asDouble(json['depth']),
    );
  }

  final String id;
  final String type;
  final double x0;
  final double y0;
  final double x1;
  final double y1;
  final double height;

  /// The compass side the piece faces: north | south | east | west.
  final String facing;

  /// floor | wall | drain | ceiling | table; null means the floor.
  final String? mounted;

  /// Height of a wall fitting's or light's fixing above the floor, mm.
  final double? mountHeight;

  /// `l` for a corner piece, whose footprint is [parts] (each `[x0, y0, x1, y1]`, mm).
  final String? shape;

  /// Which version of the piece this is (e.g. a wardrobe's `3-door`).
  final String? model;

  /// What the engine placed it for (e.g. a counter's `prep counter`).
  final String? role;
  final List<List<double>> parts;

  /// The engine's own name for the piece, when it gave one.
  final String? engineLabel;

  /// How the engine chose the spot, e.g. `headboard:west_wall`.
  final String? placementStrategy;

  /// Why the piece stands where it does, one sentence each.
  final List<String> reasons;

  /// The piece's size in mm as the engine reports it; when it doesn't, the
  /// span of its box.
  final double? widthMm;
  final double? depthMm;
  double get width => widthMm ?? (x1 - x0).abs();
  double get depth => depthMm ?? (y1 - y0).abs();

  String get label => type
      .split('_')
      .map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1))
      .join(' ');

  /// What to call the piece on screen, as the web's `itemLabel`: its label,
  /// else its role, else its type, in plain words.
  String get displayName {
    final named = [
      engineLabel,
      role,
      type,
    ].firstWhere((s) => s != null && s.trim().isNotEmpty, orElse: () => type)!;
    final text = named.replaceAll('_', ' ').trim();
    return text.isEmpty ? text : text[0].toUpperCase() + text.substring(1);
  }
}

class AnalysisOpening {
  const AnalysisOpening({
    required this.wall,
    required this.position,
    required this.width,
    required this.isDoor,
    this.height,
    this.sillHeight,
    this.inset = 0,
  });

  final String wall; // north | south | east | west
  final double position;
  final double width;
  final bool isDoor;

  /// Window height and sill height above the floor, mm.
  final double? height;
  final double? sillHeight;

  /// mm the opening stands in from its wall's line (a wall round a notch).
  final double inset;
}

/// One furnished layout from `LayoutJSON.layouts` (or `SelectedLayoutJSON`).
class AnalysisLayout {
  const AnalysisLayout({
    required this.type,
    required this.title,
    required this.score,
    required this.suitability,
    required this.roomWidth,
    required this.roomLength,
    required this.roomHeight,
    this.roomAreaM2,
    required this.furniture,
    required this.openings,
    this.cutouts = const [],
    required this.reasons,
    required this.components,
    required this.valid,
    required this.notes,
    required this.unplaced,
    required this.raw,
    this.error,
  });

  factory AnalysisLayout.fromJson(Map<String, dynamic> json) {
    final layout = (json['layout'] as Map?) ?? const {};
    final room = (json['room'] as Map?) ?? const {};
    final validation = (json['validation'] as Map?) ?? const {};
    final scoring = (json['scoring'] as Map?) ?? const {};
    final openingsJson = (json['openings'] as Map?) ?? const {};
    final components = <String, double>{};
    final rawComponents = scoring['components'];
    if (rawComponents is Map) {
      rawComponents.forEach((k, v) {
        final d = _asDouble(v);
        if (d != null && d != 0) components[k.toString()] = d;
      });
    }
    List<AnalysisOpening> openings(Object? list, bool isDoor) => [
      if (list is List)
        for (final o in list)
          if (o is Map)
            AnalysisOpening(
              wall: o['wall'] as String? ?? 'south',
              position: _asDouble(o['position']) ?? 0,
              width: _asDouble(o['width']) ?? 0,
              isDoor: isDoor,
              height: _asDouble(o['height']),
              sillHeight: _asDouble(o['sill_height']),
              inset: _asDouble(o['inset']) ?? 0,
            ),
    ];
    List<String> strings(Object? v) => [
      if (v is List)
        for (final s in v)
          if (s is String && s.trim().isNotEmpty) s,
    ];
    final explanation = strings(json['explanation']);
    return AnalysisLayout(
      type: layout['type'] as String? ?? 'layout',
      title: layout['title'] as String? ?? 'Layout',
      score: _asDouble(layout['score']) ?? 0,
      suitability: _asDouble(layout['suitability_score']) ?? 0,
      roomWidth: _asDouble(room['width']) ?? 0,
      roomLength: _asDouble(room['length']) ?? 0,
      roomHeight: _asDouble(room['height']) ?? 2800,
      roomAreaM2: _asDouble(room['area_m2']),
      furniture: [
        if (json['furniture'] is List)
          for (final f in json['furniture'] as List)
            if (f is Map)
              AnalysisFurniture.fromJson(Map<String, dynamic>.from(f)),
      ],
      cutouts: [
        if (room['cutouts'] is List)
          for (final c in room['cutouts'] as List)
            if (c is List && c.length == 4)
              [for (final v in c) _asDouble(v) ?? 0],
      ],
      openings: [
        ...openings(openingsJson['doors'], true),
        ...openings(openingsJson['windows'], false),
      ],
      reasons: explanation.isNotEmpty ? explanation : strings(json['reason']),
      components: components,
      valid: validation['valid'] != false,
      notes: strings(validation['notes']),
      unplaced: [
        if (json['unplaced_furniture'] is List)
          for (final f in json['unplaced_furniture'] as List)
            if (f is Map && f['required'] == true) (f['type'] ?? '').toString(),
      ],
      raw: json,
      error: json['error'] as String?,
    );
  }

  final String type;
  final String title;
  final double score;

  /// 0-100 suitability of this layout type for the room.
  final double suitability;
  final double roomWidth;
  final double roomLength;
  final double roomHeight;

  /// The room's floor area as the engine measured it (an L-shaped room is
  /// less than width x length); null if it did not say.
  final double? roomAreaM2;

  /// The floor area to show: the engine's, else width x length.
  double get areaM2 => roomAreaM2 ?? (roomWidth * roomLength / 1000000);

  final List<AnalysisFurniture> furniture;
  final List<AnalysisOpening> openings;

  /// Parts of the width x length rectangle that are not floor (an L-shaped
  /// room's notch), each `[x0, y0, x1, y1]` in mm.
  final List<List<double>> cutouts;
  final List<String> reasons;
  final Map<String, double> components;
  final bool valid;
  final List<String> notes;
  final List<String> unplaced;

  /// The original JSON, persisted unchanged as `SelectedLayoutJSON` so the
  /// web app can read back what the mobile user chose.
  final Map<String, dynamic> raw;

  /// Set when the engine failed to produce this particular layout.
  final String? error;

  bool get hasError => error != null;
}

/// The parsed `LayoutJSON` document: the layouts generated for one room.
class AnalysisLayoutSet {
  const AnalysisLayoutSet({
    required this.roomId,
    required this.bestType,
    required this.layouts,
  });

  /// Returns null when [layoutJson] holds no layouts.
  static AnalysisLayoutSet? from(Object? layoutJson) {
    if (layoutJson is! Map) return null;
    final list = layoutJson['layouts'];
    if (list is! List || list.isEmpty) return null;
    final layouts = [
      for (final l in list)
        if (l is Map) AnalysisLayout.fromJson(Map<String, dynamic>.from(l)),
    ]..sort((a, b) => b.score.compareTo(a.score));
    return AnalysisLayoutSet(
      roomId: layoutJson['roomId']?.toString(),
      bestType: layoutJson['bestLayout'] as String?,
      layouts: layouts,
    );
  }

  final String? roomId;
  final String? bestType;
  final List<AnalysisLayout> layouts;
}

/// A `SavedDesign` row: one room of a floor plan furnished with one layout,
/// saved from the layouts screen here or the 3D view on the web.
class SavedDesignRecord {
  const SavedDesignRecord({
    required this.designId,
    required this.floorPlanId,
    required this.roomId,
    required this.roomName,
    required this.title,
    required this.score,
    required this.layout,
    required this.modelPath,
    required this.previewPath,
    required this.updatedAt,
    this.previewUrl,
  });

  /// [previewUrl] is a short-lived link to [previewPath], since the
  /// `designs` bucket is private.
  factory SavedDesignRecord.fromJson(
    Map<String, dynamic> json, {
    String? previewUrl,
  }) {
    final layoutJson = json['LayoutJSON'];
    final score = json['Score'];
    final scoreValue = score is num ? score : num.tryParse('${score ?? ''}');
    return SavedDesignRecord(
      designId: json['DesignID'] as String,
      floorPlanId: json['FloorPlanID'] as String,
      roomId: json['RoomID'] as String,
      roomName: json['RoomName'] as String? ?? 'Room',
      title: json['Title'] as String?,
      score: scoreValue?.round(),
      layout: layoutJson is Map
          ? AnalysisLayout.fromJson(Map<String, dynamic>.from(layoutJson))
          : null,
      modelPath: json['ModelPath'] as String?,
      previewPath: json['PreviewPath'] as String?,
      updatedAt: DateTime.parse(json['UpdatedAt'] as String),
      previewUrl: previewUrl,
    );
  }

  final String designId;
  final String floorPlanId;
  final String roomId;
  final String roomName;
  final String? title;

  /// 0-100, or null when the row has none.
  final int? score;

  /// The engine layout, enough to redraw the plan and the 3D room; null when
  /// `LayoutJSON` is unreadable.
  final AnalysisLayout? layout;

  /// The exported 3D model (.glb) and preview picture (.png) in the
  /// `designs` bucket; the web saves them, the app does not yet.
  final String? modelPath;
  final String? previewPath;
  final DateTime updatedAt;
  final String? previewUrl;

  /// The files to remove from the `designs` bucket along with the row.
  List<String> get storagePaths => [?modelPath, ?previewPath];
}
