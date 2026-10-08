import 'package:flutter_test/flutter_test.dart';
import 'package:interior_design/main.dart';

void main() {
  group('validateStrongPassword (SRS FR4)', () {
    String? check(String? v) =>
        validateStrongPassword(v, emptyMessage: 'empty');

    test('rejects empty and short passwords', () {
      expect(check(null), 'empty');
      expect(check(''), 'empty');
      expect(check('Ab1!xyz'), 'At least 8 characters');
    });

    test('requires each character class', () {
      expect(check('abcdefg1!'), 'Include an uppercase letter');
      expect(check('ABCDEFG1!'), 'Include a lowercase letter');
      expect(check('Abcdefgh!'), 'Include a number');
      expect(check('Abcdefg12'), 'Include a special character');
    });

    test('accepts a strong password', () {
      expect(check('Abcdef1!'), isNull);
    });
  });
}
