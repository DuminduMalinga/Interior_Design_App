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
}
