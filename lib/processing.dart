part of 'main.dart';

/// Entry point for the AI floor-plan analysis experience.
///
/// Watches the `FloorPlanAnalysis` row for [floorPlan] (a backend pipeline
/// is expected to populate it after the image is uploaded) and forwards to
/// [RoomSelectionScreen] as soon as it reports completion. The animated
/// implementation remains private to the upload feature so this screen can
/// be navigated to independently without coupling the dashboard.
class ProcessingScreen extends StatelessWidget {
  const ProcessingScreen({required this.floorPlan, super.key})
    : _preview = false;

  /// The animation alone, without analysing anything.
  const ProcessingScreen._preview({required this.floorPlan}) : _preview = true;

  final FloorPlanRecord floorPlan;
  final bool _preview;

  @override
  Widget build(BuildContext context) {
    return _LegacyProcessingScreen(floorPlan: floorPlan, preview: _preview);
  }
}

/// The processing screen's animation, without the analysis.
@visibleForTesting
Widget processingPreviewForTest() => ProcessingScreen._preview(
  floorPlan: FloorPlanRecord(
    floorPlanId: 'preview',
    userId: 'preview',
    imagePath: '',
    status: 'Uploaded',
    uploadDateTime: DateTime(2026, 11, 1),
  ),
);
