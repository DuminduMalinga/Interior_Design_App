/// Plain data models mirroring the `public` schema tables in Supabase.
///
/// Column names are kept in their original PascalCase to match the
/// database exactly (the project's tables were not created by this app and
/// must not be altered), while Dart-side field names stay idiomatic
/// camelCase.
library;

import 'dart:ui' show Rect;

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
    this.lastSignIn,
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
  final DateTime? lastSignIn;

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
    );
  }

  final String userId;
  final String fullName;
  final String userName;
  final String email;
  final String role;
  final DateTime? lastSignIn;

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

enum DeletionStatus {
  pending,
  approved,
  rejected;

  static DeletionStatus fromRaw(String raw) => switch (raw.toLowerCase()) {
    'approved' => DeletionStatus.approved,
    'rejected' => DeletionStatus.rejected,
    _ => DeletionStatus.pending,
  };

  String get raw => switch (this) {
    DeletionStatus.pending => 'Pending',
    DeletionStatus.approved => 'Approved',
    DeletionStatus.rejected => 'Rejected',
  };
}

class DeletionRequestRecord {
  const DeletionRequestRecord({
    required this.requestId,
    required this.userId,
    required this.status,
    required this.requestedAt,
    this.username,
    this.email,
    this.fullName,
  });

  factory DeletionRequestRecord.fromJson(Map<String, dynamic> json) =>
      DeletionRequestRecord(
        requestId: json['RequestID'] as String,
        userId: json['UserID'] as String,
        status: DeletionStatus.fromRaw(json['Status'] as String? ?? 'Pending'),
        requestedAt: DateTime.parse(json['RequestedAt'] as String),
        username: json['Username'] as String?,
        email: json['Email'] as String?,
        fullName: json['FullName'] as String?,
      );

  final String requestId;
  final String userId;
  final DeletionStatus status;
  final DateTime requestedAt;
  final String? username;
  final String? email;
  final String? fullName;

  String get displayName => fullName ?? username ?? email ?? 'Unknown user';

  String get initials {
    final name = displayName.trim();
    final parts = name.split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }
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

  /// The web's layout engine only handles living rooms.
  bool get isLivingRoom =>
      RegExp('living', caseSensitive: false).hasMatch(name);
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
    );
  }

  final String id;
  final String type;
  final double x0;
  final double y0;
  final double x1;
  final double y1;
  final double height;

  String get label => type
      .split('_')
      .map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1))
      .join(' ');
}

class AnalysisOpening {
  const AnalysisOpening({
    required this.wall,
    required this.position,
    required this.width,
    required this.isDoor,
  });

  final String wall; // north | south | east | west
  final double position;
  final double width;
  final bool isDoor;
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
    required this.furniture,
    required this.openings,
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
      furniture: [
        if (json['furniture'] is List)
          for (final f in json['furniture'] as List)
            if (f is Map)
              AnalysisFurniture.fromJson(Map<String, dynamic>.from(f)),
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
  final List<AnalysisFurniture> furniture;
  final List<AnalysisOpening> openings;
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
