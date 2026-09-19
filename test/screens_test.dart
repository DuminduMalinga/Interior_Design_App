import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:interior_design/app_theme.dart';
import 'package:interior_design/main.dart';

const _sizes = {
  'mobile': Size(360, 740),
  'tablet': Size(800, 900),
  'desktop': Size(1440, 900),
};

/// Flutter tests render text in the "Ahem" font, where every glyph is a full
/// em wide, so text measures about twice as wide as it does on a device and
/// reports overflows that never happen. Loading the Roboto that ships with the
/// SDK gives realistic text metrics.
Future<void> loadRoboto() async {
  // The test runner lives under <sdk>/bin/cache/, which locates the SDK even
  // when FLUTTER_ROOT is not set.
  final exe = Platform.resolvedExecutable.replaceAll(r'\', '/');
  final cache = exe.indexOf('/bin/cache/');
  final root = Platform.environment['FLUTTER_ROOT'] ??
      (cache == -1 ? null : exe.substring(0, cache));
  if (root == null) return;
  final dir = Directory('$root/bin/cache/artifacts/material_fonts');
  if (!dir.existsSync()) return;

  final loader = FontLoader('Roboto');
  for (final file in dir.listSync().whereType<File>()) {
    final name = file.uri.pathSegments.last;
    if (name.startsWith('roboto-') &&
        name.endsWith('.ttf') &&
        !name.contains('italic')) {
      loader.addFont(Future.value(ByteData.sublistView(file.readAsBytesSync())));
    }
  }
  await loader.load();
}

Future<void> pumpScreen(WidgetTester tester, Widget screen, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(theme: AppTheme.darkTheme(), home: screen),
  );
  await tester.pump();
}

/// Renders every screen at each breakpoint. A RenderFlex overflow or any other
/// layout error is reported by the framework and fails the test.
void main() {
  setUpAll(loadRoboto);

  for (final MapEntry(key: name, value: size) in _sizes.entries) {
    group('$name layout', () {
      testWidgets('splash shows the logo then hands off to welcome', (
        tester,
      ) async {
        await pumpScreen(tester, const SplashScreen(), size);
        expect(find.text('LiviSpace'), findsOneWidget);
        expect(find.byType(WelcomeScreen), findsNothing);

        // Fire the hold timer and let the route transition run. Splash's
        // loading line and welcome's hero float both repeat forever, so
        // pumpAndSettle would never return — pump explicit durations instead.
        await tester.pump(const Duration(milliseconds: 1800));
        await tester.pump(const Duration(milliseconds: 400));
        expect(find.byType(WelcomeScreen), findsOneWidget);

        // Dispose the welcome screen's looping hero animation.
        await tester.pumpWidget(const SizedBox());
      });

      testWidgets('welcome', (tester) async {
        await pumpScreen(tester, const WelcomeScreen(), size);
        expect(find.text('LiviSpace'), findsOneWidget);
        expect(find.text('Get Started'), findsWidgets);
        // Dispose the looping hero animation.
        await tester.pumpWidget(const SizedBox());
      });

      testWidgets('sign up and sign in', (tester) async {
        await pumpScreen(tester, const AuthScreen(key: Key('up')), size);
        expect(find.text('LiviSpace'), findsOneWidget);
        expect(find.text('Create your account'), findsOneWidget);

        // A different key, so the second screen gets fresh state.
        await pumpScreen(
          tester,
          const AuthScreen(key: Key('in'), startInSignIn: true),
          size,
        );
        expect(find.text('Welcome back'), findsOneWidget);

        await tester.tap(find.text('Forgot password?'));
        await tester.pumpAndSettle();
        expect(find.byType(ForgotPasswordScreen), findsOneWidget);
      });

      testWidgets('forgot password: username and email are locked', (
        tester,
      ) async {
        await pumpScreen(tester, const ForgotPasswordScreen(), size);

        // Order on screen: Username, Email, New password, Confirm password.
        final fields = find.byType(TextFormField);
        final usernameField = tester.widget<TextFormField>(fields.at(0));
        final emailField = tester.widget<TextFormField>(fields.at(1));
        expect(usernameField.enabled, isFalse);
        expect(usernameField.initialValue, 'jamie.morgan');
        expect(emailField.enabled, isFalse);
        expect(emailField.initialValue, 'jamie.morgan@gmail.com');

        // Mismatched passwords surface a validation error instead of resetting.
        await tester.enterText(fields.at(2), 'newpass1');
        await tester.enterText(fields.at(3), 'different1');
        await tester.tap(find.text('Reset password'));
        await tester.pump();
        expect(find.text('Passwords do not match'), findsOneWidget);
      });

      testWidgets('upload', (tester) async {
        await pumpScreen(tester, const UploadScreen(), size);
        expect(find.text('Upload your floor plan'), findsOneWidget);
      });

      testWidgets('processing', (tester) async {
        await pumpScreen(tester, const ProcessingScreen(), size);
        expect(find.text('Detecting rooms...'), findsOneWidget);
        await tester.pumpWidget(const SizedBox());
      });

      testWidgets('room selection, layouts and 3D viewer', (tester) async {
        await pumpScreen(tester, const RoomSelectionScreen(), size);
        expect(find.text('We found 3 rooms'), findsOneWidget);

        // The list is below the fold on a phone.
        await tester.ensureVisible(find.text('Kitchen').last);
        await tester.tap(find.text('Kitchen').last);
        await tester.pump();

        await tester.ensureVisible(find.text('Design the Kitchen'));
        await tester.tap(find.text('Design the Kitchen'));
        await tester.pumpAndSettle();
        expect(find.text('Layouts for the Kitchen'), findsOneWidget);

        await tester.ensureVisible(find.text('View in 3D').first);
        await tester.tap(find.text('View in 3D').first);
        await tester.pumpAndSettle();
        expect(find.byIcon(Icons.zoom_in_rounded), findsOneWidget);
      });

      testWidgets('admin accounts', (tester) async {
        await pumpScreen(tester, const AdminAccountsScreen(), size);
        expect(find.text('Jamie Morgan'), findsOneWidget);

        await tester.tap(find.text('All (7)'));
        await tester.pump();
        expect(find.text('Ravi Kapoor'), findsOneWidget);
      });

      testWidgets('profile', (tester) async {
        await pumpScreen(tester, const ProfileScreen(), size);
        expect(find.text('Jamie Morgan'), findsOneWidget);
        expect(find.text('Sign out'), findsOneWidget);
      });

      testWidgets('projects', (tester) async {
        await pumpScreen(tester, const ProjectsScreen(), size);
        expect(find.text('Loft Apartment'), findsOneWidget);
        expect(find.text('Rooftop Lounge'), findsOneWidget);

        await tester.enterText(find.byType(TextFormField), 'coastal');
        await tester.pump();
        expect(find.text('Coastal Retreat'), findsOneWidget);
        expect(find.text('Loft Apartment'), findsNothing);
      });
    });
  }
}
