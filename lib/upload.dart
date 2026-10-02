part of 'main.dart';

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  PlatformFile? _picked;
  bool _uploading = false;

  bool get _selected => _picked != null;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = context.text;
    final wide = !context.screenSize.isMobile;

    final dropzone = _UploadDropzone(
      selected: _selected,
      fileName: _picked?.name,
      onSelect: _pickFile,
    );
    final details = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Accepted formats', style: text.titleMedium),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Use a clear JPG, JPEG or PNG image, up to 10 MB.',
          style: text.bodySmall?.copyWith(color: c.textMuted),
        ),
        const SizedBox(height: AppSpacing.lg),
        const _FloorPlanExamples(),
        const SizedBox(height: AppSpacing.xxl),
        AppButton(
          label: _selected ? 'Generate with AI' : 'Upload floor plan',
          icon: _selected
              ? Icons.auto_awesome_rounded
              : Icons.cloud_upload_outlined,
          loading: _uploading,
          onPressed: _selected ? _submit : _pickFile,
        ),
      ],
    );

    return _TabScaffold(
      selectedIndex: 2,
      appBar: AppBar(title: const Text('Upload floor plan')),
      body: SingleChildScrollView(
        child: AppContentFrame(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bring your space to life',
                style: context.responsive(
                  mobile: text.headlineMedium,
                  tablet: text.headlineLarge,
                  desktop: text.displayMedium,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Upload a floor plan and our AI will turn it into a smart, editable design.',
                style: text.bodyMedium?.copyWith(color: c.textSecondary),
              ),
              const SizedBox(height: AppSpacing.xxl),
              if (wide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: dropzone),
                    const SizedBox(width: AppSpacing.xxl),
                    Expanded(child: details),
                  ],
                )
              else ...[
                dropzone,
                const SizedBox(height: AppSpacing.xxl),
                details,
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// SRS UC4 business rules: JPEG/JPG/PNG only, under 10 MB.
  static const _allowedExtensions = ['jpg', 'jpeg', 'png'];
  static const _maxBytes = 10 * 1024 * 1024;

  Future<void> _pickFile() async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: _allowedExtensions,
    );
    if (file == null) return;

    final ext = (file.extension ?? file.name.split('.').last).toLowerCase();
    final size = await file.length();
    String? problem;
    if (!_allowedExtensions.contains(ext)) {
      problem =
          'Unsupported file type. Please upload a JPG, JPEG or PNG image.';
    } else if (size != null && size >= _maxBytes) {
      problem = 'That image is larger than 10 MB. Please choose a smaller one.';
    }
    if (problem != null) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(problem)));
      return;
    }
    setState(() => _picked = file);
  }

  Future<void> _submit() async {
    final file = _picked;
    final user = AuthService.instance.currentUser;
    if (file == null || user == null) return;

    setState(() => _uploading = true);
    try {
      final bytes = await file.readAsBytes();
      final ext = (file.extension ?? 'jpg').toLowerCase();
      final path = await FloorPlanRepository.instance.uploadFloorPlanImage(
        userId: user.id,
        bytes: bytes,
        fileExt: ext,
      );
      final floorPlan = await FloorPlanRepository.instance.createFloorPlan(
        userId: user.id,
        imagePath: path,
      );
      if (!mounted) return;
      setState(() {
        _uploading = false;
        _picked = null;
      });
      _openProcessing(context, floorPlan);
    } catch (error) {
      if (!mounted) return;
      setState(() => _uploading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Upload failed: $error')));
    }
  }

  void _openProcessing(BuildContext context, FloorPlanRecord floorPlan) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ProcessingScreen(floorPlan: floorPlan),
      ),
    );
  }
}

class _UploadDropzone extends StatelessWidget {
  const _UploadDropzone({
    required this.selected,
    required this.onSelect,
    this.fileName,
  });

  final bool selected;
  final String? fileName;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = context.text;

    return CustomPaint(
      painter: _DashedBorderPainter(color: c.primary.withValues(alpha: 0.65)),
      child: InkWell(
        onTap: onSelect,
        borderRadius: AppRadius.xlAll,
        child: Container(
          constraints: const BoxConstraints(minHeight: 268),
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
            color: c.primary.withValues(alpha: 0.05),
            borderRadius: AppRadius.xlAll,
            boxShadow: [
              BoxShadow(
                color: c.primary.withValues(alpha: 0.10),
                blurRadius: 36,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      c.primary.withValues(alpha: 0.28),
                      c.secondary.withValues(alpha: 0.22),
                    ],
                  ),
                  border: Border.all(color: c.primary.withValues(alpha: 0.35)),
                ),
                child: SizedBox.square(
                  dimension: 72,
                  child: Icon(
                    selected
                        ? Icons.check_rounded
                        : Icons.cloud_upload_outlined,
                    color: c.textPrimary,
                    size: 32,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                selected ? 'Floor plan selected' : 'Upload your floor plan',
                textAlign: TextAlign.center,
                style: text.titleLarge,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                selected
                    ? (fileName ?? 'Tap below to generate your AI design')
                    : 'Choose an image to begin',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: text.bodySmall?.copyWith(color: c.textMuted),
              ),
              const SizedBox(height: AppSpacing.xl),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: AppSpacing.md,
                runSpacing: AppSpacing.sm,
                children: [
                  _UploadAction(
                    icon: Icons.photo_library_outlined,
                    label: 'Choose image',
                    onTap: onSelect,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UploadAction extends StatelessWidget {
  const _UploadAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 40),
        backgroundColor: c.glassFill,
        side: BorderSide(color: c.glassBorder),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        textStyle: context.text.labelMedium,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.smAll),
      ),
    );
  }
}

class _FloorPlanExamples extends StatelessWidget {
  const _FloorPlanExamples();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final accents = [c.primary, c.accent, c.secondary];

    return Row(
      children: [
        for (var i = 0; i < accents.length; i++) ...[
          Expanded(
            child: ClipRRect(
              borderRadius: AppRadius.smAll,
              child: AspectRatio(
                aspectRatio: 1.15,
                child: ColoredBox(
                  color: c.surface,
                  child: CustomPaint(
                    painter: _ExamplePlanPainter(
                      accent: accents[i],
                      paper: c.textPrimary,
                      wall: c.surfaceElevated,
                      variant: i,
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (i < accents.length - 1) const SizedBox(width: AppSpacing.md),
        ],
      ],
    );
  }
}

class _ExamplePlanPainter extends CustomPainter {
  const _ExamplePlanPainter({
    required this.accent,
    required this.paper,
    required this.wall,
    required this.variant,
  });

  final Color accent;
  final Color paper;
  final Color wall;
  final int variant;

  @override
  void paint(Canvas canvas, Size size) {
    final sheet = Rect.fromLTWH(11, 9, size.width - 22, size.height - 18);
    canvas.drawRRect(
      RRect.fromRectAndRadius(sheet, const Radius.circular(4)),
      Paint()..color = paper,
    );
    final wallPaint = Paint()
      ..color = wall
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final detail = Paint()
      ..color = accent.withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    final fill = Paint()..color = accent.withValues(alpha: 0.12);
    final rooms = variant == 0
        ? [
            Rect.fromLTWH(sheet.left + 8, sheet.top + 8, 42, 35),
            Rect.fromLTWH(sheet.left + 54, sheet.top + 8, 35, 35),
            Rect.fromLTWH(sheet.left + 8, sheet.top + 47, 31, 42),
            Rect.fromLTWH(sheet.left + 43, sheet.top + 47, 46, 42),
          ]
        : variant == 1
        ? [
            Rect.fromLTWH(sheet.left + 8, sheet.top + 8, 34, 81),
            Rect.fromLTWH(sheet.left + 46, sheet.top + 8, 43, 38),
            Rect.fromLTWH(sheet.left + 46, sheet.top + 50, 43, 39),
          ]
        : [
            Rect.fromLTWH(sheet.left + 8, sheet.top + 8, 81, 28),
            Rect.fromLTWH(sheet.left + 8, sheet.top + 40, 39, 49),
            Rect.fromLTWH(sheet.left + 51, sheet.top + 40, 38, 49),
          ];
    for (var i = 0; i < rooms.length; i++) {
      canvas.drawRect(rooms[i], i == variant ? fill : wallPaint);
      if (i == 0) {
        canvas.drawCircle(rooms[i].center, 5, detail);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ExamplePlanPainter oldDelegate) =>
      oldDelegate.accent != accent ||
      oldDelegate.paper != paper ||
      oldDelegate.wall != wall ||
      oldDelegate.variant != variant;
}

class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Offset.zero & size,
          const Radius.circular(AppRadius.xl),
        ),
      );
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final end = (distance + 7).clamp(0, metric.length).toDouble();
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance += 13;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _LegacyProcessingScreen extends StatefulWidget {
  const _LegacyProcessingScreen({required this.floorPlan});

  final FloorPlanRecord floorPlan;

  @override
  State<_LegacyProcessingScreen> createState() => _ProcessingScreenState();
}

class _ProcessingScreenState extends State<_LegacyProcessingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Timer? _statusTimer;
  StreamSubscription<FloorPlanAnalysisRecord?>? _analysisSub;
  int _statusIndex = 0;
  bool _timedOut = false;
  bool _failed = false;

  static const _statuses = [
    'Detecting rooms...',
    'Mapping your floor plan...',
    'Preparing your smart design...',
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
    _statusTimer = Timer(const Duration(milliseconds: 1500), _advanceStatus);
    _startWatching();
  }

  void _startWatching() {
    _analysisSub?.cancel();
    _analysisSub = FloorPlanRepository.instance
        .watchAnalysis(widget.floorPlan.floorPlanId)
        .listen(
          _onAnalysisUpdate,
          onDone: () {
            if (mounted && !_timedOut) setState(() => _timedOut = true);
          },
        );
  }

  void _checkAgain() {
    setState(() {
      _timedOut = false;
      _failed = false;
    });
    _startWatching();
  }

  void _advanceStatus() {
    if (!mounted) return;
    setState(() => _statusIndex = (_statusIndex + 1) % _statuses.length);
    _statusTimer = Timer(const Duration(milliseconds: 1800), _advanceStatus);
  }

  void _onAnalysisUpdate(FloorPlanAnalysisRecord? analysis) {
    if (!mounted || analysis == null) return;
    if (analysis.isComplete) {
      _openRoomSelection();
    } else if (analysis.isFailed) {
      setState(() {
        _timedOut = true;
        _failed = true;
      });
    }
  }

  void _openRoomSelection() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => RoomSelectionScreen(floorPlan: widget.floorPlan),
      ),
    );
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    _analysisSub?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = context.text;

    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Stack(
            children: [
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _ScanlinePainter(
                      line: c.primary.withValues(alpha: 0.035),
                      glow: c.primary.withValues(alpha: 0.13),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: AppSpacing.md,
                left: AppSpacing.md,
                child: IconButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  tooltip: 'Back',
                  icon: Icon(Icons.close_rounded, color: c.textMuted),
                ),
              ),
              Center(
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) => Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox.square(
                        dimension: 254,
                        child: CustomPaint(
                          painter: _ProcessingRingPainter(
                            progress: _controller.value,
                            track: c.glassFill,
                            start: c.primary,
                            end: c.secondary,
                          ),
                          child: Center(
                            child: Transform.scale(
                              scale:
                                  1 +
                                  (_controller.value < .5
                                          ? _controller.value
                                          : 1 - _controller.value) *
                                      .12,
                              child: const _BlueprintMark(),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxl),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: Text(
                          _statuses[_statusIndex],
                          key: ValueKey(_statusIndex),
                          textAlign: TextAlign.center,
                          style: text.headlineSmall,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        _failed
                            ? 'The analysis failed for this floor plan. Try '
                                  'uploading a clearer image.'
                            : _timedOut
                            ? 'No analysis has arrived yet. Floor plans are '
                                  'analysed by the web app, so open this one '
                                  'there, then check again.'
                            : 'Our AI is analyzing every detail',
                        textAlign: TextAlign.center,
                        style: text.bodySmall?.copyWith(color: c.textMuted),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      if (_timedOut)
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: AppSpacing.md,
                          runSpacing: AppSpacing.md,
                          children: [
                            if (!_failed)
                              AppButton(
                                label: 'Check again',
                                icon: Icons.refresh_rounded,
                                expanded: false,
                                onPressed: _checkAgain,
                              ),
                            AppButton(
                              label: 'Back to dashboard',
                              expanded: false,
                              variant: AppButtonVariant.secondary,
                              onPressed: () => Navigator.of(
                                context,
                              ).popUntil((route) => route.isFirst),
                            ),
                          ],
                        )
                      else
                        SizedBox(
                          width: 168,
                          child: ClipRRect(
                            borderRadius: AppRadius.fullAll,
                            child: LinearProgressIndicator(
                              minHeight: 4,
                              color: c.primary,
                              backgroundColor: c.glassFill,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProcessingRingPainter extends CustomPainter {
  const _ProcessingRingPainter({
    required this.progress,
    required this.track,
    required this.start,
    required this.end,
  });

  final double progress;
  final Color track;
  final Color start;
  final Color end;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width * .38;
    final rect = Rect.fromCircle(center: center, radius: radius);

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = track
        ..style = PaintingStyle.stroke
        ..strokeWidth = 9,
    );

    final ring = Paint()
      ..shader = SweepGradient(colors: [start, end, start]).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 9;
    canvas.drawArc(
      rect,
      -math.pi / 2 + progress * math.pi * 2,
      math.pi * 1.45,
      false,
      ring,
    );

    final glow = Paint()
      ..color = start.withValues(alpha: 0.12)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 22);
    canvas.drawCircle(center, radius + 2, glow);
  }

  @override
  bool shouldRepaint(covariant _ProcessingRingPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.track != track ||
      oldDelegate.start != start ||
      oldDelegate.end != end;
}

class _BlueprintMark extends StatelessWidget {
  const _BlueprintMark();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: c.surface.withValues(alpha: 0.95),
        border: Border.all(color: c.primary.withValues(alpha: 0.22)),
        boxShadow: [
          BoxShadow(
            color: c.primary.withValues(alpha: 0.25),
            blurRadius: 28,
            spreadRadius: 2,
          ),
        ],
      ),
      child: SizedBox.square(
        dimension: 104,
        child: CustomPaint(painter: _BlueprintPainter(color: c.textSecondary)),
      ),
    );
  }
}

class _BlueprintPainter extends CustomPainter {
  const _BlueprintPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final rect = Rect.fromLTWH(27, 26, 50, 51);
    canvas.drawRect(rect, paint);
    canvas.drawLine(
      Offset(rect.left, rect.top + 22),
      Offset(rect.left + 22, rect.top + 22),
      paint,
    );
    canvas.drawLine(
      Offset(rect.left + 22, rect.top + 22),
      Offset(rect.left + 22, rect.bottom),
      paint,
    );
    canvas.drawLine(
      Offset(rect.left + 22, rect.top),
      Offset(rect.left + 22, rect.top + 13),
      paint,
    );
    canvas.drawCircle(Offset(rect.right - 13, rect.bottom - 13), 6, paint);
    canvas.drawCircle(Offset(rect.left + 12, rect.top + 11), 3, paint);
  }

  @override
  bool shouldRepaint(covariant _BlueprintPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _ScanlinePainter extends CustomPainter {
  const _ScanlinePainter({required this.line, required this.glow});

  final Color line;
  final Color glow;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = line
      ..strokeWidth = 1;
    for (var y = 0.0; y < size.height; y += 14) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    final glowPaint = Paint()
      ..shader = RadialGradient(colors: [glow, Colors.transparent])
          .createShader(
            Rect.fromCircle(
              center: Offset(size.width / 2, size.height / 2),
              radius: size.width * .8,
            ),
          );
    canvas.drawRect(Offset.zero & size, glowPaint);
  }

  @override
  bool shouldRepaint(covariant _ScanlinePainter oldDelegate) =>
      oldDelegate.line != line || oldDelegate.glow != glow;
}
