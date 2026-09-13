import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:interior_design/main.dart';

void main() {
  testWidgets('renders the Planly dashboard', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Good morning, Jamie'), findsOneWidget);
    expect(find.text('Recent Projects'), findsOneWidget);
    expect(find.text('Loft Apartment'), findsOneWidget);
    expect(find.byTooltip('New upload'), findsOneWidget);
    expect(find.byType(BottomNavigationBar), findsOneWidget);
  });

  testWidgets('opens the floor plan upload screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());

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
