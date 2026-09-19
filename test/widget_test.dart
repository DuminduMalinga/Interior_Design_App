import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:interior_design/main.dart';

Future<void> pumpAt(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(const MyApp());
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
}
