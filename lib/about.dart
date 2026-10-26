part of 'main.dart';

/// The version shown in the app; keep it equal to `version:` in pubspec.yaml
/// (a test checks).
const appVersion = '1.0.0';

/// The four steps, as the web's About page tells them.
const _aboutSteps = [
  (
    Icons.cloud_upload_outlined,
    'Upload a plan',
    'Add a PNG or JPG of a 2D floor plan. Walls, doors, windows and room '
        'names are read straight off the drawing.',
  ),
  (
    Icons.touch_app_outlined,
    'Pick a room',
    'Choose the room you want to furnish. Its real size comes from the '
        'measurements printed on the plan.',
  ),
  (
    Icons.compare_outlined,
    'Compare layouts',
    'Every arrangement the walls allow is tried, checked against rules for '
        'clearance and movement, and ranked.',
  ),
  (
    Icons.view_in_ar_rounded,
    '3D view',
    'Open the layout you like as a room you can turn and zoom, then save it '
        'to your designs.',
  ),
];

const _aboutRooms = [
  'Living room',
  'Bedroom',
  'Master bedroom',
  'Kitchen',
  'Bathroom',
  'Dining area',
];

const _aboutPrinciples = [
  (
    Icons.straighten_rounded,
    'Real measurements',
    'Rooms are sized from the plan\'s own dimensions, so a sofa that fits '
        'here fits at home.',
  ),
  (
    Icons.chat_bubble_outline_rounded,
    'Every choice explained',
    'Each layout says why it works: the wall it uses, the path it keeps '
        'clear.',
  ),
  (
    Icons.visibility_outlined,
    'See it before you buy',
    'Look at the room from another angle before a single piece of furniture '
        'moves.',
  ),
];

/// What LiviSpace is and how it works. The web's About page, in a form that
/// fits a phone.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = context.text;

    return Scaffold(
      appBar: AppBar(title: const Text('About LiviSpace')),
      body: DecoratedBox(
        decoration: BoxDecoration(gradient: c.backgroundGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            child: AppContentFrame(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Center(child: AppLogoMark(size: 72)),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'From a flat plan to a room you can walk through',
                    textAlign: TextAlign.center,
                    style: text.headlineMedium,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'LiviSpace reads a 2D floor plan, finds its rooms, and '
                    'furnishes the one you pick using rules for space, light '
                    'and movement. Then you see it in 3D.',
                    textAlign: TextAlign.center,
                    style: text.bodyMedium?.copyWith(color: c.textSecondary),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  const AppSectionHeader(title: 'How it works'),
                  const SizedBox(height: AppSpacing.md),
                  for (final (i, (icon, title, body)) in _aboutSteps.indexed)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: AppCard(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _StepBadge(number: i + 1, icon: icon),
                            const SizedBox(width: AppSpacing.lg),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(title, style: text.titleSmall),
                                  const SizedBox(height: AppSpacing.xs),
                                  Text(
                                    body,
                                    style: text.bodySmall?.copyWith(
                                      color: c.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: AppSpacing.lg),
                  const AppSectionHeader(title: 'Rooms it can furnish'),
                  const SizedBox(height: AppSpacing.md),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      for (final room in _aboutRooms)
                        AppStatusChip(label: room, status: AppStatus.info),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  const AppSectionHeader(title: 'Built to be trusted'),
                  const SizedBox(height: AppSpacing.md),
                  for (final (icon, title, body) in _aboutPrinciples)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: AppCard(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(icon, color: c.primary),
                            const SizedBox(width: AppSpacing.lg),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(title, style: text.titleSmall),
                                  const SizedBox(height: AppSpacing.xs),
                                  Text(
                                    body,
                                    style: text.bodySmall?.copyWith(
                                      color: c.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: AppSpacing.xl),
                  Center(
                    child: Text(
                      'Version $appVersion\n© ${DateTime.now().year} LiviSpace',
                      textAlign: TextAlign.center,
                      style: text.bodySmall?.copyWith(color: c.textMuted),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StepBadge extends StatelessWidget {
  const _StepBadge({required this.number, required this.icon});

  final int number;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      label: 'Step $number',
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: c.primary.withValues(alpha: 0.14),
        ),
        child: SizedBox.square(
          dimension: 40,
          child: Icon(icon, size: 20, color: c.primary),
        ),
      ),
    );
  }
}

/// The questions people ask, answered from what the app does. Each answer
/// names the screen to go to.
const _helpTopics = [
  (
    'Getting started',
    [
      (
        'What floor plans can I upload?',
        'A clear JPG, JPEG or PNG image, up to 10 MB. Open the Upload tab, '
            'choose the file and start the analysis.',
      ),
      (
        'How do I know my plan is ready?',
        'The app finds the rooms for you. If Email notifications is on '
            '(Profile tab), we also email you when the plan is ready.',
      ),
      (
        'Can I use the same plans on the web?',
        'Yes. Sign in with the same account on the web and your plans, '
            'layouts and saved designs are there too, so you can start on '
            'one and finish on the other.',
      ),
    ],
  ),
  (
    'Rooms and layouts',
    [
      (
        'Which rooms can be furnished?',
        'Living room, bedroom, master bedroom, kitchen, bathroom and dining '
            'area. The room is recognised by the name printed on the plan, '
            'so a room with another name, such as a garage, can\'t be '
            'furnished yet.',
      ),
      (
        'How are the layouts chosen?',
        'Every arrangement the walls allow is checked against rules for '
            'clearance and movement, scored, and shown best first. Use the '
            'options above the layouts (for example persons, seats or '
            'mobility needs) to plan for you; the layouts update when you '
            'change one.',
      ),
      (
        'How do I save a layout?',
        'Open a layout and confirm it. It is saved to your designs and, if '
            'Email notifications is on, we email you a note.',
      ),
    ],
  ),
  (
    'Your designs',
    [
      (
        'Where are my saved designs?',
        'In the Designs tab, newest first. Tap one to open it in 3D.',
      ),
      (
        'How do I remove a saved design?',
        'In the Designs tab, tap the bin on its card and confirm. Your '
            'floor plan and its layouts stay.',
      ),
    ],
  ),
  (
    'Your account',
    [
      (
        'How do I change my photo or name?',
        'In the Profile tab, tap your picture to choose or remove a photo, '
            'or open Edit profile to change your details.',
      ),
      (
        'Can I use a light look?',
        'Yes: Profile → Appearance switches between dark and light.',
      ),
      (
        'I forgot my password.',
        'On the sign-in screen tap Forgot password?, enter your email and '
            'we\'ll send you a link to set a new one.',
      ),
      (
        'How do I delete my account?',
        'Profile → Delete my account. You confirm with your password, and '
            'your account, plans and saved designs are removed for good.',
      ),
    ],
  ),
];

/// Help: answers to common questions, grouped by what you are doing.
class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = context.text;

    return Scaffold(
      appBar: AppBar(title: const Text('Help & support')),
      body: DecoratedBox(
        decoration: BoxDecoration(gradient: c.backgroundGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            child: AppContentFrame(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('How can we help?', style: text.headlineSmall),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Answers to the questions people ask most.',
                    style: text.bodyMedium?.copyWith(color: c.textSecondary),
                  ),
                  for (final (group, questions) in _helpTopics) ...[
                    const SizedBox(height: AppSpacing.xl),
                    Text(
                      group.toUpperCase(),
                      style: text.labelMedium?.copyWith(color: c.textMuted),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    AppCard(
                      padding: EdgeInsets.zero,
                      child: ClipRRect(
                        borderRadius: AppRadius.lgAll,
                        child: Theme(
                          // the card draws its own edges; drop the tile lines
                          data: Theme.of(
                            context,
                          ).copyWith(dividerColor: Colors.transparent),
                          child: Column(
                            children: [
                              for (final (i, (question, answer))
                                  in questions.indexed) ...[
                                ExpansionTile(
                                  tilePadding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.lg,
                                  ),
                                  childrenPadding: const EdgeInsets.fromLTRB(
                                    AppSpacing.lg,
                                    0,
                                    AppSpacing.lg,
                                    AppSpacing.lg,
                                  ),
                                  expandedAlignment: Alignment.centerLeft,
                                  title: Text(question, style: text.titleSmall),
                                  children: [
                                    Text(
                                      answer,
                                      style: text.bodyMedium?.copyWith(
                                        color: c.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                                if (i != questions.length - 1)
                                  Divider(height: 1, color: c.border),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
