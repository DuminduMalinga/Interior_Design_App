part of 'main.dart';

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  bool _hasSelection = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: _background,
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: const Text(
          'Upload floor plan',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Bring your space to life',
                style: TextStyle(
                  fontSize: 25,
                  height: 1.12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -.5,
                ),
              ),
              const SizedBox(height: 9),
              const Text(
                'Upload a floor plan and our AI will turn it into a smart, editable design.',
                style: TextStyle(color: _muted, fontSize: 13, height: 1.45),
              ),
              const SizedBox(height: 28),
              _UploadDropzone(
                hasSelection: _hasSelection,
                onTap: () => setState(() => _hasSelection = true),
                onCameraTap: () => setState(() => _hasSelection = true),
                onGalleryTap: () => setState(() => _hasSelection = true),
              ),
              const SizedBox(height: 26),
              const Text(
                'Accepted formats',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 5),
              const Text(
                'Use a clear image, sketch, or scanned document.',
                style: TextStyle(color: _muted, fontSize: 11),
              ),
              const SizedBox(height: 13),
              const _ExamplePlans(),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [_blue, _violet]),
                    borderRadius: BorderRadius.circular(17),
                    boxShadow: [
                      BoxShadow(
                        color: _blue.withValues(alpha: .24),
                        blurRadius: 22,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ElevatedButton.icon(
                    onPressed: _hasSelection
                        ? () => _showProcessingMessage(context)
                        : () => setState(() => _hasSelection = true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(17),
                      ),
                    ),
                    icon: Icon(
                      _hasSelection
                          ? Icons.auto_awesome_rounded
                          : Icons.cloud_upload_outlined,
                      size: 20,
                    ),
                    label: Text(
                      _hasSelection ? 'Generate with AI' : 'Upload floor plan',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showProcessingMessage(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Your floor plan is ready for AI processing.'),
      ),
    );
  }
}

class _UploadDropzone extends StatelessWidget {
  const _UploadDropzone({
    required this.hasSelection,
    required this.onTap,
    required this.onCameraTap,
    required this.onGalleryTap,
  });

  final bool hasSelection;
  final VoidCallback onTap;
  final VoidCallback onCameraTap;
  final VoidCallback onGalleryTap;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedBorderPainter(),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          height: 268,
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: _blue.withValues(alpha: .045),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: _blue.withValues(alpha: .10),
                blurRadius: 35,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      _blue.withValues(alpha: .28),
                      _violet.withValues(alpha: .22),
                    ],
                  ),
                  border: Border.all(color: _blue.withValues(alpha: .35)),
                ),
                child: Icon(
                  hasSelection
                      ? Icons.check_rounded
                      : Icons.cloud_upload_outlined,
                  color: const Color(0xFFB9D5FF),
                  size: 31,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                hasSelection ? 'Floor plan selected' : 'Upload your floor plan',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                hasSelection
                    ? 'Tap below to generate your AI design'
                    : 'Drag and drop or choose an image to begin',
                textAlign: TextAlign.center,
                style: const TextStyle(color: _muted, fontSize: 11),
              ),
              const SizedBox(height: 19),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _UploadOption(
                    icon: Icons.camera_alt_outlined,
                    label: 'Camera',
                    onTap: onCameraTap,
                  ),
                  const SizedBox(width: 10),
                  _UploadOption(
                    icon: Icons.photo_library_outlined,
                    label: 'Gallery',
                    onTap: onGalleryTap,
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

class _UploadOption extends StatelessWidget {
  const _UploadOption({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFFD5E4FF),
        side: BorderSide(color: Colors.white.withValues(alpha: .13)),
        backgroundColor: Colors.white.withValues(alpha: .04),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      icon: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 11)),
    );
  }
}

class _ExamplePlans extends StatelessWidget {
  const _ExamplePlans();

  static const examples = [
    Color(0xFF4D9BFF),
    Color(0xFF35C5B5),
    Color(0xFF8A6BFF),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < examples.length; i++) ...[
          Expanded(
            child: _ExampleThumbnail(accent: examples[i], variant: i),
          ),
          if (i != examples.length - 1) const SizedBox(width: 10),
        ],
      ],
    );
  }
}

class _ExampleThumbnail extends StatelessWidget {
  const _ExampleThumbnail({required this.accent, required this.variant});

  final Color accent;
  final int variant;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: AspectRatio(
        aspectRatio: 1.15,
        child: ColoredBox(
          color: const Color(0xFF17202D),
          child: CustomPaint(
            painter: _ExampleFloorPlanPainter(accent: accent, variant: variant),
          ),
        ),
      ),
    );
  }
}

class _ExampleFloorPlanPainter extends CustomPainter {
  const _ExampleFloorPlanPainter({required this.accent, required this.variant});

  final Color accent;
  final int variant;

  @override
  void paint(Canvas canvas, Size size) {
    final paper = Paint()..color = const Color(0xFFE9EDF3);
    final wall = Paint()
      ..color = const Color(0xFF344253)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final accentPaint = Paint()
      ..color = accent.withValues(alpha: .85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    final roomFill = Paint()..color = accent.withValues(alpha: .12);
    final sheet = Rect.fromLTWH(11, 9, size.width - 22, size.height - 18);
    canvas.drawRRect(
      RRect.fromRectAndRadius(sheet, const Radius.circular(4)),
      paper,
    );

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
      canvas.drawRect(rooms[i], i == variant ? roomFill : wall);
      if (i == 0) {
        canvas.drawCircle(rooms[i].center, 5, accentPaint);
      }
    }

    final door = Path()
      ..moveTo(rooms[0].right - 10, rooms[0].bottom)
      ..quadraticBezierTo(
        rooms[0].right - 10,
        rooms[0].bottom - 10,
        rooms[0].right,
        rooms[0].bottom - 10,
      );
    canvas.drawPath(door, accentPaint);
    canvas.drawLine(
      Offset(sheet.left + 8, sheet.bottom - 5),
      Offset(sheet.right - 8, sheet.bottom - 5),
      Paint()
        ..color = const Color(0xFF9AA7B8)
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(covariant _ExampleFloorPlanPainter oldDelegate) =>
      oldDelegate.accent != accent || oldDelegate.variant != variant;
}

class _DashedBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _blue.withValues(alpha: .65)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(24)),
      );
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
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
