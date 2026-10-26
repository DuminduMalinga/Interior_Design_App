import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Whether the app is light or dark, kept on the device. Like the web's
/// `theme-preference`, there are just the two choices, and dark is the
/// default.
class ThemeController extends ValueNotifier<ThemeMode> {
  ThemeController([super.value = ThemeMode.dark]);

  static final ThemeController instance = ThemeController();

  static const storageKey = 'theme-preference';

  /// The stored value as a mode; anything but "light" is dark.
  static ThemeMode parse(String? stored) =>
      stored == 'light' ? ThemeMode.light : ThemeMode.dark;

  /// Reads the saved choice. Call before the first frame so the app does
  /// not flash the wrong theme.
  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      value = parse(prefs.getString(storageKey));
    } catch (_) {
      // storage unavailable: keep the default for this session
    }
  }

  /// Applies a choice and remembers it.
  Future<void> set(ThemeMode mode) async {
    value = mode == ThemeMode.light ? ThemeMode.light : ThemeMode.dark;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        storageKey,
        value == ThemeMode.light ? 'light' : 'dark',
      );
    } catch (_) {
      // still applies for this session
    }
  }
}
