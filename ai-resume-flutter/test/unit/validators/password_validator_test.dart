import 'package:flutter_test/flutter_test.dart';
import 'package:ai_resume_flutter/utils/validators/password_validator.dart';

void main() {
  group('PasswordValidator', () {
    group('validate', () {
      test('should return null for valid password', () {
        expect(PasswordValidator.validate('Abc12345'), isNull);
        expect(PasswordValidator.validate('Test1234'), isNull);
      });

      test('should return error for empty password', () {
        expect(PasswordValidator.validate(''), '请输入密码');
      });

      test('should return error for too short password', () {
        expect(PasswordValidator.validate('Abc12'), isNotNull);
      });

      test('should return error for password without letters', () {
        expect(PasswordValidator.validate('12345678'), isNotNull);
      });

      test('should return error for password without numbers', () {
        expect(PasswordValidator.validate('abcdefgh'), isNotNull);
      });
    });

    group('validateStrong', () {
      test('should return null for strong password', () {
        expect(PasswordValidator.validateStrong('Abc123!@'), isNull);
        expect(PasswordValidator.validateStrong('Test@1234'), isNull);
      });

      test('should return error for missing lowercase', () {
        expect(PasswordValidator.validateStrong('ABC123!@'), isNotNull);
      });

      test('should return error for missing uppercase', () {
        expect(PasswordValidator.validateStrong('abc123!@'), isNotNull);
      });

      test('should return error for missing special char', () {
        expect(PasswordValidator.validateStrong('Abc12345'), isNotNull);
      });
    });

    group('calculateStrength', () {
      test('should return 0 for empty password', () {
        expect(PasswordValidator.calculateStrength(''), equals(0));
      });

      test('should return at least 3 for valid password', () {
        expect(
          PasswordValidator.calculateStrength('Abc12345'),
          greaterThanOrEqualTo(3),
        );
      });

      test('should return 5 for very strong password', () {
        expect(
          PasswordValidator.calculateStrength('Abc123!@XyZ'),
          equals(5),
        );
      });
    });

    group('getStrengthLabel', () {
      test('should return correct labels', () {
        expect(PasswordValidator.getStrengthLabel('a'), equals('弱'));
        expect(PasswordValidator.getStrengthLabel('Abc'), equals('较弱'));
        expect(PasswordValidator.getStrengthLabel('Abc123'), equals('中等'));
        expect(PasswordValidator.getStrengthLabel('Abc123!@'), equals('强'));
        expect(PasswordValidator.getStrengthLabel('Abc123!@XyZ'), equals('很强'));
      });
    });

    group('isWeakPassword', () {
      test('should identify weak passwords', () {
        expect(PasswordValidator.isWeakPassword('Abc'), isTrue);
        expect(PasswordValidator.isWeakPassword('Abc123'), isTrue);
      });

      test('should not identify strong passwords as weak', () {
        expect(PasswordValidator.isWeakPassword('Abc123!@'), isFalse);
      });
    });

    group('isCommonWeakPassword', () {
      test('should detect common weak passwords', () {
        expect(PasswordValidator.isCommonWeakPassword('password'), isTrue);
        expect(PasswordValidator.isCommonWeakPassword('12345678'), isTrue);
        expect(PasswordValidator.isCommonWeakPassword('qwerty'), isTrue);
      });

      test('should return false for strong passwords', () {
        expect(PasswordValidator.isCommonWeakPassword('MySecure!23'), isFalse);
      });
    });

    group('validateOrThrow', () {
      test('should throw for invalid password', () {
        expect(
          () => PasswordValidator.validateOrThrow(''),
          throwsA(isA<ValidationException>()),
        );
      });

      test('should throw for common weak password', () {
        expect(
          () => PasswordValidator.validateOrThrow('password'),
          throwsA(isA<ValidationException>()),
        );
      });

      test('should not throw for strong password', () {
        expect(
          () => PasswordValidator.validateOrThrow('Abc123!@'),
          returnsNormally,
        );
      });
    });
  });
}
