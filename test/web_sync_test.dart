import 'package:flutter_test/flutter_test.dart';
import 'package:interior_design/data/detector_service.dart';
import 'package:interior_design/data/models.dart';

/// The pieces shared with the web project: the notification choices on the
/// `User` row, the admin audit log, and where the wall detector runs.
void main() {
  group('NotificationPrefs', () {
    test('defaults match the web: email and news on, browser off', () {
      const prefs = NotificationPrefs();
      expect(prefs.toJson(), {
        'email': true,
        'browser': false,
        'updates': true,
      });
      expect(NotificationPrefs.fromJson(null).email, isTrue);
      expect(NotificationPrefs.fromJson('junk').updates, isTrue);
    });

    test('reads stored choices and keeps the browser one when changing', () {
      final prefs = NotificationPrefs.fromJson({
        'email': false,
        'browser': true,
        'updates': true,
      });
      expect(prefs.email, isFalse);
      final next = prefs.copyWith(updates: false);
      expect(next.toJson(), {
        'email': false,
        'browser': true,
        'updates': false,
      });
    });

    test('AppUserProfile carries them', () {
      final profile = AppUserProfile.fromJson({
        'UserID': 'u',
        'Email': 'a@b.c',
        'FullName': 'A B',
        'UserName': 'ab',
        'NotificationPrefs': {'email': false},
      });
      expect(profile.notifications.email, isFalse);
      expect(profile.notifications.updates, isTrue);
    });
  });

  test('AuditEntry reads a log line and words it for the admin page', () {
    final entry = AuditEntry.fromJson({
      'Action': 'delete_user',
      'CreatedAt': '2026-10-20T10:00:00Z',
      'TargetID': 't',
      'Detail': {'email': 'x@y.z', 'filesRemoved': 3, 'empty': ''},
    });
    expect(entry.label, 'Delete user');
    expect(entry.summary, 'email: x@y.z · filesRemoved: 3');
  });

  test('the wall detector defaults to the emulator host', () {
    expect(DetectorEnv.url, 'http://10.0.2.2:8000');
  });
}
