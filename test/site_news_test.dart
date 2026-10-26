import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:interior_design/app_theme.dart';
import 'package:interior_design/data/site_news.dart';
import 'package:interior_design/main.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:interior_design/env.dart';

import 'test_utils.dart';

const _sizes = {
  'mobile': Size(360, 740),
  'tablet': Size(800, 900),
  'desktop': Size(1440, 900),
};

/// The live totals and the admin's product-news form: the two things the web
/// has that the app lacked.
void main() {
  setUpAll(loadRoboto);
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: SupabaseEnv.url,
      publishableKey: SupabaseEnv.anonKey,
    );
  });

  group('SiteStats.fromRpc', () {
    test('reads the row get_site_stats returns, in a list or alone', () {
      final row = {'UserCount': 12, 'FloorPlanCount': 34, 'LayoutCount': 56};
      for (final data in [
        [row],
        row,
      ]) {
        final stats = SiteStats.fromRpc(data)!;
        expect(stats.users, 12);
        expect(stats.floorPlans, 34);
        expect(stats.layouts, 56);
      }
    });

    test('reads counts that arrive as text (bigint), like the web', () {
      final stats = SiteStats.fromRpc([
        {'UserCount': '1200', 'FloorPlanCount': '3', 'LayoutCount': '45678'},
      ])!;
      expect(stats.users, 1200);
      expect(stats.layouts, 45678);
    });

    test('is null for anything unreadable, so the screen shows dashes', () {
      expect(SiteStats.fromRpc(null), isNull);
      expect(SiteStats.fromRpc(<Object>[]), isNull);
      expect(SiteStats.fromRpc('junk'), isNull);
      expect(
        SiteStats.fromRpc([
          {'UserCount': 1},
        ]),
        isNull,
      );
      expect(
        SiteStats.fromRpc([
          {'UserCount': 'x', 'FloorPlanCount': 1, 'LayoutCount': 1},
        ]),
        isNull,
      );
    });
  });

  test('formatCount groups thousands and dashes the unknown', () {
    expect(formatCount(null), '—');
    expect(formatCount(0), '0');
    expect(formatCount(999), '999');
    expect(formatCount(1000), '1,000');
    expect(formatCount(1234567), '1,234,567');
    expect(formatCount(-4200), '-4,200');
  });

  group('news messages', () {
    test('every reason the server gives has words for an admin', () {
      for (final reason in [
        'not_configured',
        'limit',
        'provider_error',
        'domain_not_verified',
        'no_address',
      ]) {
        expect(newsProblem(reason), isNot(reason), reason: reason);
        expect(newsProblem(reason), isNotEmpty);
      }
      expect(newsProblem('not_configured'), contains('RESEND_API_KEY'));
      expect(newsProblem('limit'), contains('email limit'));
    });

    test('an unknown reason is shown as given; none gives a plain line', () {
      expect(newsProblem('Admins only.'), 'Admins only.');
      expect(newsProblem(null), 'The message could not be sent.');
      expect(newsProblem(''), 'The message could not be sent.');
    });

    test('says who will get it, as the web does', () {
      expect(newsReadersNote(null), contains('everyone who turned on'));
      expect(newsReadersNote(0), contains('Nobody has Product news'));
      expect(newsReadersNote(1), contains('1 person who'));
      expect(newsReadersNote(7), contains('7 people who'));
      expect(newsReadersNote(7), contains("can't be unsent"));
    });

    test('says how many it went to', () {
      expect(newsSentMessage(1), 'Product news sent to 1 person.');
      expect(newsSentMessage(12), 'Product news sent to 12 people.');
    });
  });

  group('welcome totals', () {
    for (final MapEntry(key: name, value: size) in _sizes.entries) {
      testWidgets('$name: dashes until loaded, then the live counts', (
        tester,
      ) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final load = Completer<SiteStats?>();
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.darkTheme(),
            home: WelcomeScreen(loadStats: () => load.future),
          ),
        );
        await tester.pump();

        expect(find.text('Registered users'), findsOneWidget);
        expect(find.text('Layouts generated'), findsOneWidget);
        expect(find.text('Floor plans uploaded'), findsOneWidget);
        expect(find.text('Processing time'), findsOneWidget);
        expect(find.text('< 2 min'), findsOneWidget);
        expect(find.text('—'), findsNWidgets(3));

        load.complete(
          const SiteStats(users: 1234, floorPlans: 56, layouts: 7890),
        );
        await tester.pump();
        expect(find.text('1,234'), findsOneWidget);
        expect(find.text('56'), findsOneWidget);
        expect(find.text('7,890'), findsOneWidget);
        expect(find.text('—'), findsNothing);
      });
    }

    testWidgets('a failed lookup leaves dashes, not an error', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme(),
          home: WelcomeScreen(loadStats: () async => throw Exception('down')),
        ),
      );
      await tester.pump();
      await tester.pump();
      expect(find.text('—'), findsNWidgets(3));
      expect(tester.takeException(), isNull);
    });

    testWidgets('no totals from the server leaves dashes too', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme(),
          home: WelcomeScreen(loadStats: () async => null),
        ),
      );
      await tester.pump();
      await tester.pump();
      expect(find.text('—'), findsNWidgets(3));
    });
  });
}
