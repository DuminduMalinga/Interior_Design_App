/// Plain data models mirroring the `public` schema tables in Supabase.
///
/// Column names are kept in their original PascalCase to match the
/// database exactly (the project's tables were not created by this app and
/// must not be altered), while Dart-side field names stay idiomatic
/// camelCase.
library;

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

  factory AppUserProfile.fromJson(Map<String, dynamic> json) =>
      AppUserProfile(
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
        .map(
          (w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1),
        )
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

  bool get isComplete => status.toLowerCase() == 'completed';
  bool get isFailed => status.toLowerCase() == 'failed';
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
        width: json['Width'] == null
            ? null
            : (json['Width'] as num).toDouble(),
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
