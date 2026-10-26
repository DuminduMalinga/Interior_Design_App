import 'dart:async';

import 'package:flutter/foundation.dart';

/// How strong a new password is, as the web's sign-up scores it: 25 points
/// each for eight characters, both cases, a digit and a symbol.
class PasswordStrength {
  const PasswordStrength(this.score, this.label);

  /// 0, 25, 50, 75 or 100.
  final int score;

  /// Weak, Fair, Good or Strong; empty for no password.
  final String label;

  /// How full the meter is, 0 to 1.
  double get fraction => score / 100;

  /// Scores [password]; an empty one has no label, so no meter shows.
  static PasswordStrength of(String password) {
    if (password.isEmpty) return const PasswordStrength(0, '');
    var score = 0;
    if (password.length >= 8) score += 25;
    if (RegExp('[a-z]').hasMatch(password) &&
        RegExp('[A-Z]').hasMatch(password)) {
      score += 25;
    }
    if (RegExp(r'\d').hasMatch(password)) score += 25;
    if (RegExp('[^A-Za-z0-9]').hasMatch(password)) score += 25;

    final label = score <= 25
        ? 'Weak'
        : score <= 50
        ? 'Fair'
        : score <= 75
        ? 'Good'
        : 'Strong';
    return PasswordStrength(score, label);
  }
}

/// What is known about a username the user is typing.
enum UsernameStatus {
  /// Too short, not valid, or the lookup failed: say nothing.
  unknown,
  checking,
  available,
  taken,
}

/// Checks a username as it is typed, as the web's sign-up does: it waits for
/// a pause in typing, asks the server, and ignores an answer that arrives
/// after the user has typed something else.
class UsernameChecker extends ValueNotifier<UsernameStatus> {
  UsernameChecker({
    required this.lookup,
    this.pause = const Duration(milliseconds: 400),
  }) : super(UsernameStatus.unknown);

  /// Asks the server whether a username is free.
  final Future<bool> Function(String username) lookup;

  /// How long typing must stop before the server is asked.
  final Duration pause;

  /// Names the form accepts; others are left for its own error message.
  static final _valid = RegExp(r'^[a-zA-Z0-9_]+$');
  static const minLength = 3;

  Timer? _timer;
  int _request = 0;
  bool _disposed = false;

  /// Call with the field's text on every change.
  void onChanged(String text) {
    final name = text.trim();
    _timer?.cancel();
    // anything still on its way back is now out of date
    final request = ++_request;

    if (name.length < minLength || !_valid.hasMatch(name)) {
      _set(UsernameStatus.unknown);
      return;
    }

    _set(UsernameStatus.checking);
    _timer = Timer(pause, () async {
      bool free;
      try {
        free = await lookup(name);
      } catch (_) {
        if (request == _request) _set(UsernameStatus.unknown);
        return;
      }
      if (request != _request) return;
      _set(free ? UsernameStatus.available : UsernameStatus.taken);
    });
  }

  /// Forget the current name, e.g. when the form switches to sign in.
  void reset() {
    _timer?.cancel();
    _request++;
    _set(UsernameStatus.unknown);
  }

  void _set(UsernameStatus status) {
    if (!_disposed) value = status;
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    super.dispose();
  }
}
