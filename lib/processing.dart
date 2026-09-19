part of 'main.dart';

/// Entry point for the AI floor-plan analysis experience.
///
/// The animated implementation remains private to the upload feature so this
/// screen can be navigated to independently without coupling the dashboard.
class ProcessingScreen extends StatelessWidget {
  const ProcessingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _LegacyProcessingScreen();
  }
}
