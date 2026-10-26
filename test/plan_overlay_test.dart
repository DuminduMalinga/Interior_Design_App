import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:interior_design/app_theme.dart';
import 'package:interior_design/plan_overlay.dart';

import 'test_utils.dart';

/// The floor plan with its rooms drawn over it, as the web's room selection.
void main() {
  setUpAll(loadRoboto);

  Rect box(double l, double t, double r, double b) => Rect.fromLTRB(l, t, r, b);
  List<Offset> corners(Rect r) => [
    r.topLeft,
    r.topRight,
    r.bottomRight,
    r.bottomLeft,
  ];

  // Left half can be furnished, right half cannot; an L-shaped room fills the
  // bottom with a notch, so taps can be aimed at each.
  final bedroom = PlanOverlayRoom(
    name: 'Bedroom',
    outline: corners(box(0, 0, 0.5, 0.5)),
    selectable: true,
  );
  final garage = PlanOverlayRoom(
    name: 'Garage',
    outline: corners(box(0.5, 0, 1, 0.5)),
    selectable: false,
  );
  const lOutline = [
    Offset(0, 0.5),
    Offset(1, 0.5),
    Offset(1, 0.7),
    Offset(0.4, 0.7),
    Offset(0.4, 1),
    Offset(0, 1),
  ];
  const living = PlanOverlayRoom(
    name: 'Living room',
    outline: lOutline,
    selectable: true,
  );

  Future<Rect> pump(
    WidgetTester tester, {
    int? selected,
    String? imageUrl,
    Map<String, int> counts = const {},
    double aspectRatio = 1.5,
    ThemeData? theme,
    List<int>? picked,
    List<int>? blocked,
    Size size = const Size(360, 740),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: theme ?? AppTheme.darkTheme(),
        home: Scaffold(
          body: SingleChildScrollView(
            child: PlanOverlay(
              rooms: [bedroom, garage, living],
              aspectRatio: aspectRatio,
              selected: selected,
              imageUrl: imageUrl,
              counts: counts,
              onSelect: (i) => picked?.add(i),
              onBlocked: (i) => blocked?.add(i),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    return tester.getRect(find.byType(AspectRatio));
  }

  Offset at(Rect plan, double x, double y) =>
      plan.topLeft + Offset(x * plan.width, y * plan.height);

  testWidgets('the plan keeps the image\'s proportions', (tester) async {
    final plan = await pump(tester, aspectRatio: 1312 / 1199);
    expect(plan.width / plan.height, closeTo(1312 / 1199, 0.01));
  });

  testWidgets('tapping a room that can be furnished picks it', (tester) async {
    final picked = <int>[];
    final blocked = <int>[];
    final plan = await pump(tester, picked: picked, blocked: blocked);
    await tester.tapAt(at(plan, 0.25, 0.25));
    expect(picked, [0]);
    expect(blocked, isEmpty);
  });

  testWidgets('tapping a room that cannot be furnished says so', (
    tester,
  ) async {
    final picked = <int>[];
    final blocked = <int>[];
    final plan = await pump(tester, picked: picked, blocked: blocked);
    await tester.tapAt(at(plan, 0.75, 0.25));
    expect(picked, isEmpty);
    expect(blocked, [1]);
  });

  testWidgets('an L-shaped room is picked only where it is', (tester) async {
    final picked = <int>[];
    final plan = await pump(tester, picked: picked);
    await tester.tapAt(at(plan, 0.2, 0.9)); // the L's tall arm
    await tester.tapAt(at(plan, 0.8, 0.6)); // the L's wide arm
    expect(picked, [2, 2]);

    picked.clear();
    await tester.tapAt(at(plan, 0.8, 0.9)); // the notch beside the arm
    expect(picked, isEmpty);
  });

  testWidgets('a tap outside every room does nothing', (tester) async {
    final picked = <int>[];
    final blocked = <int>[];
    final plan = await pump(tester, picked: picked, blocked: blocked);
    // the bottom right corner, beyond the L's notch, is no room at all
    await tester.tapAt(at(plan, 0.9, 0.95));
    expect(picked, isEmpty);
    expect(blocked, isEmpty);
  });

  testWidgets('says there is no preview when it has no image', (tester) async {
    await pump(tester);
    expect(find.text('No preview available'), findsOneWidget);
    expect(find.byType(Image), findsNothing);
  });

  testWidgets('keeps the outlines when the image cannot load', (tester) async {
    final picked = <int>[];
    final plan = await pump(
      tester,
      imageUrl: 'http://localhost:1/plan.png',
      picked: picked,
    );
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump();
    expect(find.text('No preview available'), findsOneWidget);
    await tester.tapAt(at(plan, 0.25, 0.25));
    expect(picked, [0]);
  });

  testWidgets('shows what was found, 0 for what is missing', (tester) async {
    await pump(tester, counts: {'Wall': 31, 'Room': 3, 'Door': 4});
    expect(find.text('31'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('4'), findsOneWidget);
    expect(find.text('0'), findsOneWidget); // no windows recorded
    for (final label in ['Walls', 'Rooms', 'Doors', 'Windows']) {
      expect(find.text(label), findsOneWidget, reason: label);
    }
  });

  testWidgets('shows no counts row when there are none', (tester) async {
    await pump(tester);
    expect(find.text('Walls'), findsNothing);
  });

  testWidgets('labels only the chosen room, on the plan', (tester) async {
    await pump(tester, selected: 0);
    final paint = tester.widget<CustomPaint>(
      find.descendant(
        of: find.byType(PlanOverlay),
        matching: find.byWidgetPredicate(
          (w) => w is CustomPaint && w.painter is PlanOverlayPainter,
        ),
      ),
    );
    final painter = paint.painter! as PlanOverlayPainter;
    expect(painter.selected, 0);
    expect(painter.rooms.length, 3);
  });

  testWidgets('describes itself to a screen reader', (tester) async {
    await pump(tester);
    expect(
      find.bySemanticsLabel(RegExp('Floor plan with 3 rooms')),
      findsOneWidget,
    );
  });

  for (final (name, size) in const [
    ('mobile', Size(360, 740)),
    ('tablet', Size(800, 900)),
    ('desktop', Size(1440, 900)),
  ]) {
    for (final (themeName, theme) in [
      ('dark', AppTheme.darkTheme()),
      ('light', AppTheme.lightTheme()),
    ]) {
      testWidgets('draws without overflow: $name $themeName', (tester) async {
        await pump(
          tester,
          size: size,
          theme: theme,
          selected: 2,
          counts: {'Wall': 31, 'Room': 3, 'Door': 4, 'Window': 5},
        );
        expect(tester.takeException(), isNull);
      });
    }
  }
}
