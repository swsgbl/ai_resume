import 'package:flutter_test/flutter_test.dart';
import 'package:ai_resume_flutter/utils/validators/email_validator.dart';

void main() {
  group('EmailValidator', () {
    group('validate', () {
      test('should return null for valid email', () {
        expect(EmailValidator.validate('test@example.com'), isNull);
        expect(EmailValidator.validate('user.qq.com'), isNull);
        expect(EmailValidator.validate('test.163.com'), isNull);
      });

      test('should return error message for empty email', () {
        expect(EmailValidator.validate(''), '请输入邮箱地址');
        expect(EmailValidator.validate(''), '请输入邮箱地址');
      });

      test('should return error message for invalid email format', () {
        expect(EmailValidator.validate('invalid'), isNotNull);
        expect(EmailValidator.validate('test@'), isNotNull);
        expect(EmailValidator.validate('@example.com'), isNotNull);
      });
    });

    group('isValid', () {
      test('should return true for valid emails', () {
        expect(EmailValidator.isValid('test@example.com'), true);
        expect(EmailValidator.isValid('user@qq.com'), true);
      });

      test('should return false for invalid emails', () {
        expect(EmailValidator.isValid('invalid'), false);
        expect(EmailValidator.isValid('test@'), false);
      });
    });

    group('extractDomain', () {
      test('should extract domain correctly', () {
        expect(EmailValidator.extractDomain('test@example.com'), 'example.com');
        expect(EmailValidator.extractDomain('user@qq.com'), 'qq.com');
      });

      test('should return null for invalid email', () {
        expect(EmailValidator.extractDomain('invalid'), isNull);
      });
    });

    group('isCommonProvider', () {
      test('should return true for common providers', () {
        expect(EmailValidator.isCommonProvider('test@qq.com'), true);
        expect(EmailValidator.isCommonProvider('user@163.com'), true);
        expect(EmailValidator.isCommonProvider('user@gmail.com'), true);
      });

      test('should return false for uncommon providers', () {
        expect(EmailValidator.isCommonProvider('test@unknown.com'), false);
      });
    });

    group('normalize', () {
      test('should convert to lowercase', () {
        expect(EmailValidator.normalize('Test@Example.COM'), 'test@example.com');
      });

      test('should trim whitespace', () {
        expect(EmailValidator.normalize('  test@example.com  '), 'test@example.com');
      });
    });
  });
}
