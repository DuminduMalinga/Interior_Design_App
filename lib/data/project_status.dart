import 'models.dart';

/// How far a floor plan has been taken through the design flow, as the web's
/// dashboard tells it (`DesignStatus`): the analysis row's status, or
/// "uploaded" when there is none yet.
enum ProjectStage {
  uploaded,
  detected,
  layoutReady,
  layoutSelected;

  /// The stage an analysis row's `Status` stands for. Anything else (an
  /// analysis still running, or a failed one) counts as just uploaded.
  static ProjectStage fromStatus(String? status) =>
      switch (status?.trim().toLowerCase()) {
        'detected' => detected,
        'layoutready' => layoutReady,
        'layoutselected' => layoutSelected,
        _ => uploaded,
      };

  /// Where the plan is: the web's `STATUS_LABEL`.
  String get label => switch (this) {
    uploaded => 'Uploaded',
    detected => 'Rooms detected',
    layoutReady => 'Layouts ready',
    layoutSelected => 'Layout chosen',
  };

  /// What to do next: the web's `NEXT_STEP`.
  String get nextStep => switch (this) {
    uploaded => 'Upload again to analyse',
    detected => 'Pick a room',
    layoutReady => 'Compare layouts',
    layoutSelected => 'Open layouts',
  };

  /// Whether the plan has furniture layouts, generated or chosen: what the
  /// web counts as a "finished plan".
  bool get isFinished => this == layoutReady || this == layoutSelected;
}

/// One floor plan and what has been done with it.
class ProjectSummary {
  const ProjectSummary({
    required this.plan,
    required this.stage,
    required this.title,
    required this.roomCount,
    required this.updatedAt,
    this.selectedRoomName,
    this.layoutTitle,
    this.score,
  });

  /// Joins a floor plan with its analysis row, as the web's `toDesign` does.
  factory ProjectSummary.of(
    FloorPlanRecord plan,
    FloorPlanAnalysisRecord? analysis,
  ) {
    final rooms = analysis?.rooms ?? const <AnalysisRoom>[];
    final selectedId = analysis?.selectedRoomId;
    String? roomName;
    if (selectedId != null) {
      for (final r in rooms) {
        if (r.id == selectedId) roomName = r.name;
      }
    }

    final chosen = analysis?.selectedLayoutJson;
    final layout = chosen is Map ? chosen['layout'] : null;
    final rawScore = layout is Map ? layout['score'] : null;

    return ProjectSummary(
      plan: plan,
      stage: ProjectStage.fromStatus(analysis?.status),
      title: titleFor(roomName: roomName, roomCount: rooms.length),
      roomCount: rooms.length,
      selectedRoomName: roomName,
      layoutTitle: layout is Map ? layout['title'] as String? : null,
      score: rawScore is num ? rawScore.round() : null,
      updatedAt: analysis?.updatedAt ?? plan.uploadDateTime,
    );
  }

  /// What to call a plan: the room it was taken to, else how many rooms it
  /// has, else "Floor plan" (the web's `designTitle`).
  static String titleFor({String? roomName, required int roomCount}) {
    if (roomName != null && roomName.trim().isNotEmpty) return roomName;
    if (roomCount > 0) {
      return 'Floor plan with $roomCount ${roomCount == 1 ? 'room' : 'rooms'}';
    }
    return 'Floor plan';
  }

  final FloorPlanRecord plan;
  final ProjectStage stage;
  final String title;
  final int roomCount;
  final String? selectedRoomName;
  final String? layoutTitle;

  /// Score of the chosen layout out of 100; null until one is chosen.
  final int? score;

  /// When the plan last changed: its analysis, else its upload.
  final DateTime updatedAt;
}

/// The totals on Home, as the web's dashboard shows them.
class ProjectStats {
  const ProjectStats({
    required this.plans,
    required this.finished,
    required this.lastScore,
  });

  /// Counts the plans, how many are finished, and the score of the most
  /// recently changed plan that has one.
  factory ProjectStats.of(Iterable<ProjectSummary> projects) {
    var plans = 0, finished = 0;
    ProjectSummary? latest;
    for (final p in projects) {
      plans++;
      if (p.stage.isFinished) finished++;
      if (p.score != null &&
          (latest == null || p.updatedAt.isAfter(latest.updatedAt))) {
        latest = p;
      }
    }
    return ProjectStats(
      plans: plans,
      finished: finished,
      lastScore: latest?.score,
    );
  }

  final int plans;
  final int finished;

  /// Null when no plan has a chosen layout yet.
  final int? lastScore;
}
