import 'package:flutter_test/flutter_test.dart';
import 'package:chdc_counselling/core/validation/validators.dart';

void main() {
  group('phone validation', () {
    test('normalizes supported Nigerian formats', () {
      const validNumbers = [
        '08031234567',
        '0803 123 4567',
        '8031234567',
        '2348031234567',
        '+2348031234567',
      ];
      for (final number in validNumbers) {
        expect(normalizeNgPhone(number), '+2348031234567');
      }
    });

    test('rejects invalid formats', () {
      const invalidNumbers = [
        '',
        '12345',
        '+2348031234',
        '+2346031234567',
        '08231234567',
        '+14155552671',
      ];
      for (final number in invalidNumbers) {
        expect(normalizeNgPhone(number), isNull, reason: number);
      }
    });

    test('formats a normalized number for display', () {
      expect(formatNgPhone('+2348031234567'), '+234 803 123 4567');
    });

    test('returns the contract error messages', () {
      expect(phoneError(''), 'This field is required.');
      expect(
        phoneError('12345'),
        'Enter a valid Nigerian mobile number, e.g. 08031234567.',
      );
    });
  });

  group('account validation', () {
    test('normalizes valid usernames and rejects invalid ones', () {
      expect(usernameError('amina_b'), isNull);
      expect(usernameError('Amina_B'), isNull);
      expect(usernameError('1abc'), isNotNull);
      expect(usernameError('ab'), isNotNull);
      expect(usernameError('a-b'), isNotNull);
    });

    test('checks password strength and confirmation', () {
      expect(passwordError('1234567'), 'Password must be at least 8 characters.');
      expect(passwordError('12345678'), "Password can't be entirely numeric.");
      expect(passwordError('S3cure!pass'), isNull);
      expect(confirmPasswordError('secret', 'wrong'), 'Passwords do not match.');
      expect(confirmPasswordError('secret', 'secret'), isNull);
    });

    test('checks six digit OTP format', () {
      expect(otpError('12345'), 'Enter the 6-digit code.');
      expect(otpError('123456'), isNull);
    });
  });
}
