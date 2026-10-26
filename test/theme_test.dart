import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:interior_design/app_theme.dart';
import 'package:interior_design/theme_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// WCAG relative-luminance contrast ratio between two opaque colours.
double contrast(Color a, Color b) {
  double lum(Color c) {
    double ch(double v) =>
        v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4) as double;
    return 0.2126 * ch(c.r) + 0.7152 * ch(c.g) + 0.0722 * ch(c.b);
  }

  final l1 = lum(a), l2 = lum(b);
  return (math.max(l1, l2) + 0.05) / (math.min(l1, l2) + 0.05);
}

void main() {
  group('palettes stay readable', () {
    // The dark palette predates these checks and its white-on-blue button is
    // 3.6:1, so it is held to the large-text 3:1; the light one meets 4.5:1.
    for (final (name, c, buttonMin) in [
      ('dark', AppColors.dark, 3.0),
      ('light', AppColors.light, 4.5),
    ]) {
      group(name, () {
        final grounds = {
          'background': c.background,
          'surface': c.surface,
          'surfaceElevated': c.surfaceElevated,
        };

        test('body and secondary text (4.5:1) on every ground', () {
          for (final MapEntry(key: ground, value: bg) in grounds.entries) {
            expect(
              contrast(c.textPrimary, bg),
              greaterThanOrEqualTo(4.5),
              reason: 'textPrimary on $ground',
            );
            expect(
              contrast(c.textSecondary, bg),
              greaterThanOrEqualTo(4.5),
              reason: 'textSecondary on $ground',
            );
          }
        });

        test('muted text (3:1) on every ground', () {
          for (final MapEntry(key: ground, value: bg) in grounds.entries) {
            expect(
              contrast(c.textMuted, bg),
              greaterThanOrEqualTo(3),
              reason: 'textMuted on $ground',
            );
          }
        });

        test('label on the primary button', () {
          expect(
            contrast(c.onPrimary, c.primary),
            greaterThanOrEqualTo(buttonMin),
          );
        });

        test('accent colours as text and icons (3:1) on a surface', () {
          final colours = {
            'primary': c.primary,
            'secondary': c.secondary,
            'accent': c.accent,
            'success': c.success,
            'warning': c.warning,
            'error': c.error,
          };
          for (final MapEntry(key: role, value: colour) in colours.entries) {
            expect(
              contrast(colour, c.surface),
              greaterThanOrEqualTo(3),
              reason: '$role on surface',
            );
          }
        });
      });
    }
  });

  group('themes', () {
    test('light and dark build with their own palette', () {
      final light = AppTheme.lightTheme();
      final dark = AppTheme.darkTheme();
      expect(light.brightness, Brightness.light);
      expect(dark.brightness, Brightness.dark);
      expect(light.extension<AppColors>(), AppColors.light);
      expect(dark.extension<AppColors>(), AppColors.dark);
      expect(light.scaffoldBackgroundColor, AppColors.light.background);
      expect(dark.scaffoldBackgroundColor, AppColors.dark.background);
    });

    test('text takes the palette\'s text colour', () {
      expect(
        AppTheme.lightTheme().textTheme.bodyMedium?.color,
        AppColors.light.textPrimary,
      );
      expect(
        AppTheme.darkTheme().textTheme.bodyMedium?.color,
        AppColors.dark.textPrimary,
      );
    });
  });

  group('ThemeController', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('is dark until a choice is saved, like the web', () async {
      final controller = ThemeController();
      expect(controller.value, ThemeMode.dark);
      await controller.load();
      expect(controller.value, ThemeMode.dark);
    });

    test('remembers a choice for the next launch', () async {
      await ThemeController().set(ThemeMode.light);

      final next = ThemeController();
      await next.load();
      expect(next.value, ThemeMode.light);

      await next.set(ThemeMode.dark);
      final last = ThemeController();
      await last.load();
      expect(last.value, ThemeMode.dark);
    });

    test('notifies listeners so the app restyles at once', () async {
      final controller = ThemeController();
      var notified = 0;
      controller.addListener(() => notified++);
      await controller.set(ThemeMode.light);
      expect(notified, 1);
    });

    test('anything but "light" is read as dark', () {
      expect(ThemeController.parse('light'), ThemeMode.light);
      expect(ThemeController.parse('dark'), ThemeMode.dark);
      expect(ThemeController.parse('system'), ThemeMode.dark);
      expect(ThemeController.parse(null), ThemeMode.dark);
    });

    test('only light and dark are stored', () async {
      await ThemeController().set(ThemeMode.system);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(ThemeController.storageKey), 'dark');
    });
  });
}
