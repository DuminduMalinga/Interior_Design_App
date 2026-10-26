import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:interior_design/app_theme.dart';
import 'package:interior_design/main.dart';

import 'test_utils.dart';

const _sizes = {
  'mobile': Size(360, 740),
  'tablet': Size(800, 900),
  'desktop': Size(1440, 900),
};

Future<void> _pump(
  WidgetTester tester,
  Widget screen,
  Size size,
  ThemeData theme,
) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(theme: theme, home: screen));
  await tester.pump();
}

/// The About and Help screens behind Profile → Support.
void main() {
  setUpAll(loadRoboto);

  test('the version shown is the one in pubspec.yaml', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final version = RegExp(
      r'^version:\s*(\d+\.\d+\.\d+)',
      multiLine: true,
    ).firstMatch(pubspec)?.group(1);
    expect(appVersion, version);
  });

  for (final MapEntry(key: name, value: size) in _sizes.entries) {
    for (final (themeName, theme) in [
      ('dark', AppTheme.darkTheme()),
      ('light', AppTheme.lightTheme()),
    ]) {
      group('$name $themeName', () {
        testWidgets('about tells what the app does, with no overflow', (
          tester,
        ) async {
          await _pump(tester, const AboutScreen(), size, theme);
          expect(find.text('About LiviSpace'), findsOneWidget);
          expect(
            find.text('From a flat plan to a room you can walk through'),
            findsOneWidget,
          );
          for (final step in [
            'Upload a plan',
            'Pick a room',
            'Compare layouts',
            '3D view',
          ]) {
            expect(find.text(step), findsOneWidget, reason: step);
          }
          // every room the app has a layout engine for
          for (final room in [
            'Living room',
            'Bedroom',
            'Master bedroom',
            'Kitchen',
            'Bathroom',
            'Dining area',
          ]) {
            expect(find.text(room), findsOneWidget, reason: room);
          }
          expect(find.textContaining('Version $appVersion'), findsOneWidget);
        });

        testWidgets('help lists its questions, with no overflow', (
          tester,
        ) async {
          await _pump(tester, const HelpScreen(), size, theme);
          expect(find.text('Help & support'), findsOneWidget);
          expect(find.text('What floor plans can I upload?'), findsOneWidget);
          expect(find.text('How do I delete my account?'), findsOneWidget);
        });
      });
    }
  }

  group('help', () {
    testWidgets('an answer opens when its question is tapped', (tester) async {
      await _pump(
        tester,
        const HelpScreen(),
        _sizes['mobile']!,
        AppTheme.darkTheme(),
      );
      const question = 'What floor plans can I upload?';
      expect(find.textContaining('up to 10 MB'), findsNothing);

      await tester.tap(find.text(question));
      await tester.pumpAndSettle();
      expect(find.textContaining('up to 10 MB'), findsOneWidget);

      await tester.tap(find.text(question));
      await tester.pumpAndSettle();
      expect(find.textContaining('up to 10 MB'), findsNothing);
    });

    testWidgets('every question can be opened and has an answer', (
      tester,
    ) async {
      await _pump(
        tester,
        const HelpScreen(),
        _sizes['desktop']!,
        AppTheme.lightTheme(),
      );
      final tiles = find.byType(ExpansionTile);
      final count = tester.widgetList(tiles).length;
      expect(count, greaterThanOrEqualTo(10));
      for (var i = 0; i < count; i++) {
        final tile = tiles.at(i);
        await tester.ensureVisible(tile);
        await tester.tap(tile);
        await tester.pumpAndSettle();
        final shown = tester.widget<ExpansionTile>(tile);
        final answer = (shown.children.single as Text).data ?? '';
        expect(answer.trim(), isNotEmpty);
        expect(find.text(answer), findsOneWidget);
      }
    });

    testWidgets('does not invent a way to reach support', (tester) async {
      await _pump(
        tester,
        const HelpScreen(),
        _sizes['mobile']!,
        AppTheme.darkTheme(),
      );
      // no address or link until the team provides a real one
      expect(find.textContaining('@'), findsNothing);
      expect(find.textContaining('http'), findsNothing);
    });
  });
}
