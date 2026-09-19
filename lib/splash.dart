part of 'main.dart';

/// First thing the app shows: the logo and a brief loading line, then it
/// hands off to [WelcomeScreen]. There is nothing to actually wait on yet
/// (no backend, no cached session) — this exists to give the brand a beat
/// on screen before the "Get Started" flow, the way a native splash would.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  static const _holdDuration = Duration(milliseconds: 1800);

  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(_holdDuration, _openWelcome);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _openWelcome() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const WelcomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = context.text;

    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppLogoMark(
                  size: context.responsive(
                    mobile: 124,
                    tablet: 148,
                    desktop: 164,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  'LiviSpace',
                  style: context.responsive(
                    mobile: text.headlineMedium,
                    tablet: text.headlineLarge,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Design spaces for better living',
                  style: text.bodyMedium?.copyWith(color: c.textMuted),
                ),
                const SizedBox(height: AppSpacing.huge),
                const _LoadingLine(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A slim indeterminate progress line, styled from the brand gradient instead
/// of Material's default indicator so the splash reads as one system with
/// the rest of the app.
class _LoadingLine extends StatelessWidget {
  const _LoadingLine();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return SizedBox(
      width: context.responsive(mobile: 150, tablet: 180, desktop: 190),
      height: 5,
      child: ClipRRect(
        borderRadius: AppRadius.fullAll,
        child: DecoratedBox(
          decoration: BoxDecoration(color: c.glassFill),
          child: LinearProgressIndicator(
            backgroundColor: Colors.transparent,
            valueColor: AlwaysStoppedAnimation(c.primary),
            // Indeterminate: value stays null, so it animates on its own.
          ),
        ),
      ),
    );
  }
}
