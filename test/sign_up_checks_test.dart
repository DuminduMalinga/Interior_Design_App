import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:interior_design/app_theme.dart';
import 'package:interior_design/data/sign_up_checks.dart';
import 'package:interior_design/env.dart';
import 'package:interior_design/main.dart';
import 'package:interior_design/sign_up_widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'test_utils.dart';

/// The live checks on the sign-up form, as the web's sign-up has them.
void main() {
  setUpAll(loadRoboto);
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: SupabaseEnv.url,
      publishableKey: SupabaseEnv.anonKey,
    );
  });

  group('PasswordStrength', () {
    void expectScore(String password, int score, String label) {
      final s = PasswordStrength.of(password);
      expect(s.score, score, reason: password);
      expect(s.label, label, reason: password);
    }

    test('has no label until something is typed', () {
      expectScore('', 0, '');
    });

    test(
      'scores 25 for each of: eight characters, both cases, digit, symbol',
      () {
        expectScore('abc', 0, 'Weak'); // one case, short
        expectScore('abcdefgh', 25, 'Weak'); // length only
        expectScore('Abcdefgh', 50, 'Fair'); // + both cases
        expectScore('Abcdefg1', 75, 'Good'); // + digit
        expectScore('Abcdef1!', 100, 'Strong'); // + symbol
      },
    );

    test('each rule counts on its own, in any combination', () {
      expectScore('1234567', 25, 'Weak'); // digit
      expectScore('!!!!!!!', 25, 'Weak'); // symbol
      expectScore('Ab', 25, 'Weak'); // both cases
      expectScore('A1', 25, 'Weak');
      expectScore('a1!', 50, 'Fair'); // digit + symbol
      expectScore('aB1!', 75, 'Good'); // cases + digit + symbol, short
    });

    test('a symbol is anything that is not a letter or digit', () {
      expectScore('________', 50, 'Fair'); // length + symbol
      expectScore('        ', 50, 'Fair');
    });

    test('fills the meter in quarters', () {
      expect(PasswordStrength.of('Abcdef1!').fraction, 1.0);
      expect(PasswordStrength.of('Abcdefg1').fraction, 0.75);
      expect(PasswordStrength.of('').fraction, 0);
    });
  });

  group('UsernameChecker', () {
    late List<String> asked;
    late UsernameChecker checker;
    var free = true;

    UsernameChecker make(Future<bool> Function(String) lookup) =>
        UsernameChecker(lookup: lookup);

    setUp(() {
      asked = [];
      free = true;
      checker = make((name) async {
        asked.add(name);
        return free;
      });
    });

    tearDown(() => checker.dispose());

    testWidgets('says nothing for a name that is too short', (tester) async {
      checker.onChanged('ab');
      await tester.pump(const Duration(seconds: 1));
      expect(checker.value, UsernameStatus.unknown);
      expect(asked, isEmpty);
    });

    testWidgets('does not ask about a name the form will reject anyway', (
      tester,
    ) async {
      for (final bad in ['has space', 'bad!name', 'émile', 'a-b-c']) {
        checker.onChanged(bad);
        await tester.pump(const Duration(seconds: 1));
        expect(checker.value, UsernameStatus.unknown, reason: bad);
      }
      expect(asked, isEmpty);
    });

    testWidgets('shows checking at once, then the answer after a pause', (
      tester,
    ) async {
      checker.onChanged('maria_99');
      expect(checker.value, UsernameStatus.checking);
      expect(asked, isEmpty, reason: 'waits for a pause in typing');

      await tester.pump(const Duration(milliseconds: 399));
      expect(asked, isEmpty);
      await tester.pump(const Duration(milliseconds: 2));
      await tester.pump();
      expect(asked, ['maria_99']);
      expect(checker.value, UsernameStatus.available);
    });

    testWidgets('reports a name that is taken', (tester) async {
      free = false;
      checker.onChanged('maria');
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump();
      expect(checker.value, UsernameStatus.taken);
    });

    testWidgets('asks only about where typing stopped', (tester) async {
      checker.onChanged('mar');
      await tester.pump(const Duration(milliseconds: 200));
      checker.onChanged('mari');
      await tester.pump(const Duration(milliseconds: 200));
      checker.onChanged('maria');
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump();
      expect(asked, ['maria']);
    });

    testWidgets('ignores spaces around the name', (tester) async {
      checker.onChanged('  maria  ');
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump();
      expect(asked, ['maria']);
    });

    testWidgets('ignores an answer that arrives after the name changed', (
      tester,
    ) async {
      final slow = Completer<bool>();
      final answers = <String, Future<bool>>{
        'first': slow.future,
        'second': Future.value(false),
      };
      final c = make((name) => answers[name]!);
      addTearDown(c.dispose);

      c.onChanged('first');
      await tester.pump(const Duration(milliseconds: 500)); // asks, waits
      c.onChanged('second');
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump();
      expect(c.value, UsernameStatus.taken, reason: 'the second answer');

      slow.complete(true); // the first answer comes in late
      await tester.pump();
      expect(c.value, UsernameStatus.taken, reason: 'the late one is dropped');
    });

    testWidgets('typing too little again cancels a check on its way', (
      tester,
    ) async {
      final slow = Completer<bool>();
      final c = make((_) => slow.future);
      addTearDown(c.dispose);

      c.onChanged('maria');
      await tester.pump(const Duration(milliseconds: 500));
      c.onChanged('ma'); // deleted back down
      expect(c.value, UsernameStatus.unknown);
      slow.complete(true);
      await tester.pump();
      expect(c.value, UsernameStatus.unknown);
    });

    testWidgets('says nothing if the lookup fails', (tester) async {
      final c = make((_) async => throw Exception('offline'));
      addTearDown(c.dispose);
      c.onChanged('maria');
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump();
      expect(c.value, UsernameStatus.unknown);
    });

    testWidgets('a late failure does not wipe a newer answer', (tester) async {
      final failing = Completer<bool>();
      final answers = <String, Future<bool>>{
        'first': failing.future,
        'second': Future.value(true),
      };
      final c = make((name) => answers[name]!);
      addTearDown(c.dispose);

      c.onChanged('first');
      await tester.pump(const Duration(milliseconds: 500));
      c.onChanged('second');
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump();
      failing.completeError(Exception('late'));
      await tester.pump();
      expect(c.value, UsernameStatus.available);
    });

    testWidgets('reset forgets the name and any check on its way', (
      tester,
    ) async {
      checker.onChanged('maria');
      checker.reset();
      expect(checker.value, UsernameStatus.unknown);
      await tester.pump(const Duration(seconds: 1));
      expect(asked, isEmpty);
    });

    testWidgets('disposing stops a check that has not started', (tester) async {
      final c = make((name) async {
        asked.add(name);
        return true;
      });
      c.onChanged('maria');
      c.dispose();
      await tester.pump(const Duration(seconds: 1));
      expect(asked, isEmpty);
    });

    testWidgets('a check finishing after disposal does not throw', (
      tester,
    ) async {
      final slow = Completer<bool>();
      final c = make((_) => slow.future);
      c.onChanged('maria');
      await tester.pump(const Duration(milliseconds: 500));
      c.dispose();
      slow.complete(true);
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });

  group('the username line', () {
    Future<void> show(WidgetTester tester, UsernameStatus status) =>
        tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.darkTheme(),
            home: Scaffold(body: UsernameStatusLine(status: status)),
          ),
        );

    testWidgets('is silent until there is something to say', (tester) async {
      await show(tester, UsernameStatus.unknown);
      expect(find.byType(Text), findsNothing);
    });

    testWidgets('says which it found, in the web\'s words', (tester) async {
      await show(tester, UsernameStatus.checking);
      expect(find.text('Checking…'), findsOneWidget);
      await show(tester, UsernameStatus.available);
      expect(find.text('Username available'), findsOneWidget);
      await show(tester, UsernameStatus.taken);
      expect(find.text('Username already exists'), findsOneWidget);
    });
  });

  group('the strength meter', () {
    Future<void> show(
      WidgetTester tester,
      String password, {
      ThemeData? theme,
    }) => tester.pumpWidget(
      MaterialApp(
        theme: theme ?? AppTheme.darkTheme(),
        home: Scaffold(body: PasswordStrengthMeter(password: password)),
      ),
    );

    testWidgets('is hidden until something is typed', (tester) async {
      await show(tester, '');
      expect(find.text('Password strength'), findsNothing);
    });

    testWidgets('names the strength and fills the bar to match', (
      tester,
    ) async {
      for (final (password, label, fraction) in const [
        ('abc', 'Weak', 0.0),
        ('Abcdefgh', 'Fair', 0.5),
        ('Abcdefg1', 'Good', 0.75),
        ('Abcdef1!', 'Strong', 1.0),
      ]) {
        await show(tester, password);
        await tester.pumpAndSettle();
        expect(find.text('Password strength'), findsOneWidget);
        expect(find.text(label), findsOneWidget, reason: password);
        final bar = tester.widget<AnimatedFractionallySizedBox>(
          find.byType(AnimatedFractionallySizedBox),
        );
        expect(bar.widthFactor, fraction, reason: password);
      }
    });

    test('goes red, amber, blue, green with strength', () {
      const c = AppColors.dark;
      Color of(String p) =>
          PasswordStrengthMeter.colorFor(PasswordStrength.of(p), c);
      expect(of('abc'), c.error);
      expect(of('Abcdefgh'), c.warning);
      expect(of('Abcdefg1'), c.primary);
      expect(of('Abcdef1!'), c.success);
    });

    testWidgets('can be heard by a screen reader', (tester) async {
      await show(tester, 'Abcdefg1');
      expect(find.bySemanticsLabel('Password strength: Good'), findsOneWidget);
    });

    testWidgets('fits the narrowest screen in both themes', (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      for (final theme in [AppTheme.darkTheme(), AppTheme.lightTheme()]) {
        await show(tester, 'Abcdef1!', theme: theme);
        expect(tester.takeException(), isNull);
      }
    });
  });

  group('on the sign-up form', () {
    Future<void> openSignUp(WidgetTester tester, {Size? size}) async {
      tester.view.physicalSize = size ?? const Size(360, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(theme: AppTheme.darkTheme(), home: const AuthScreen()),
      );
      await tester.pump();
    }

    testWidgets('typing a password shows how strong it is', (tester) async {
      await openSignUp(tester);
      expect(find.text('Password strength'), findsNothing);
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'),
        'Abcdefg1',
      );
      await tester.pumpAndSettle();
      expect(find.text('Password strength'), findsOneWidget);
      expect(find.text('Good'), findsOneWidget);

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'),
        'Abcdef1!',
      );
      await tester.pumpAndSettle();
      expect(find.text('Strong'), findsOneWidget);
    });

    testWidgets('typing a username starts a check, a short one does not', (
      tester,
    ) async {
      await openSignUp(tester);
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Username'),
        'ab',
      );
      await tester.pump();
      expect(find.text('Checking…'), findsNothing);

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Username'),
        'maria',
      );
      await tester.pump();
      expect(find.text('Checking…'), findsOneWidget);

      // leaving the screen with a check waiting must not leave a timer behind
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('the sign-in form has neither check', (tester) async {
      tester.view.physicalSize = const Size(360, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme(),
          home: const AuthScreen(startInSignIn: true),
        ),
      );
      await tester.pump();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'),
        'Abcdef1!',
      );
      await tester.pump();
      expect(find.text('Password strength'), findsNothing);
      expect(find.widgetWithText(TextFormField, 'Username'), findsNothing);
    });

    for (final (name, size) in const [
      ('mobile', Size(360, 900)),
      ('tablet', Size(800, 900)),
      ('desktop', Size(1440, 900)),
    ]) {
      testWidgets('fits a $name screen with every message showing', (
        tester,
      ) async {
        await openSignUp(tester, size: size);
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Username'),
          'maria',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Password'),
          'Abcdef1!',
        );
        await tester.pump();
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      });
    }
  });
}
