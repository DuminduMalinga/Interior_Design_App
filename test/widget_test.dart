import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:interior_design/app_theme.dart';
import 'package:interior_design/main.dart';

/// Pumps the dashboard (the app itself opens on the welcome screen) at the
/// given logical size.
Future<void> pumpAt(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(theme: AppTheme.darkTheme(), home: const DashboardScreen()),
  );
}

void main() {
  testWidgets('mobile: single column with bottom nav and FAB', (tester) async {
    await pumpAt(tester, const Size(400, 800));

    expect(find.text('Good morning, Jamie'), findsOneWidget);
    expect(find.text('Recent Projects'), findsOneWidget);
    expect(find.text('Loft Apartment'), findsOneWidget);
    expect(find.byType(BottomNavigationBar), findsOneWidget);
    expect(find.byTooltip('New upload'), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);
  });

  testWidgets('tablet: compact rail replaces bottom nav', (tester) async {
    await pumpAt(tester, const Size(800, 900));

    final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
    expect(rail.extended, isFalse);
    expect(find.byType(BottomNavigationBar), findsNothing);
    expect(find.text('Upload floor plan'), findsOneWidget);
  });

  testWidgets('desktop: extended rail and side tip card', (tester) async {
    await pumpAt(tester, const Size(1440, 900));

    final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
    expect(rail.extended, isTrue);
    expect(find.byType(BottomNavigationBar), findsNothing);
    expect(find.textContaining('Pro tip'), findsOneWidget);
  });

  testWidgets('Projects tab opens the projects screen', (tester) async {
    await pumpAt(tester, const Size(400, 800));

    await tester.tap(find.text('Projects'));
    await tester.pumpAndSettle();

    expect(find.byType(ProjectsScreen), findsOneWidget);
    expect(find.text('Rooftop Lounge'), findsOneWidget);
  });

  testWidgets('See all opens the projects screen', (tester) async {
    await pumpAt(tester, const Size(400, 800));

    await tester.tap(find.text('See all'));
    await tester.pumpAndSettle();

    expect(find.byType(ProjectsScreen), findsOneWidget);
  });

  testWidgets('opens the floor plan upload screen', (
    WidgetTester tester,
  ) async {
    // 800x600 is the test surface this screen was written against; the upload
    // dropzone overflows at phone widths.
    await pumpAt(tester, const Size(800, 600));

    await tester.tap(find.text('Upload'));
    await tester.pumpAndSettle();

    expect(find.text('Upload floor plan'), findsNWidgets(2));
    expect(find.text('Upload your floor plan'), findsOneWidget);
    expect(find.text('Accepted formats'), findsOneWidget);
    expect(find.byIcon(Icons.camera_alt_outlined), findsOneWidget);
    expect(find.byIcon(Icons.photo_library_outlined), findsOneWidget);
  });

  testWidgets('renders the AI processing screen', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: ProcessingScreen()));
    await tester.pump();

    expect(find.text('Detecting rooms...'), findsOneWidget);
    expect(find.byType(ProcessingScreen), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}
