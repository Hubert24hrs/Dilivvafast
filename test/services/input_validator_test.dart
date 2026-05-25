import 'package:fast_delivery/core/security/input_validator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('InputValidator Tests', () {
    group('Email Validation', () {
      test('valid email passes', () {
        expect(InputValidator.validateEmail('test@example.com'), isNull);
        expect(InputValidator.validateEmail('user.name@domain.co.uk'), isNull);
      });

      test('invalid email fails', () {
        expect(InputValidator.validateEmail('invalid'), isNotNull);
        expect(InputValidator.validateEmail('test@'), isNotNull);
        expect(InputValidator.validateEmail('@example.com'), isNotNull);
      });

      test('empty email fails', () {
        expect(InputValidator.validateEmail(''), isNotNull);
        expect(InputValidator.validateEmail(null), isNotNull);
      });
    });

    group('Password Validation', () {
      test('strong password passes', () {
        expect(InputValidator.validatePassword('Password123'), isNull);
        expect(InputValidator.validatePassword('Str0ngP@ss'), isNull);
      });

      test('weak password fails', () {
        expect(InputValidator.validatePassword('short'), isNotNull);
        expect(InputValidator.validatePassword('alllowercase123'), isNotNull);
        expect(InputValidator.validatePassword('ALLUPPERCASE123'), isNotNull);
        expect(InputValidator.validatePassword('NoNumbers'), isNotNull);
      });
    });

    group('Phone Validation', () {
      test('valid phone passes', () {
        expect(InputValidator.validatePhone('+2348012345678'), isNull);
        expect(InputValidator.validatePhone('08012345678'), isNull);
      });

      test('invalid phone fails', () {
        expect(InputValidator.validatePhone('123'), isNotNull);
        expect(InputValidator.validatePhone(''), isNotNull);
      });
    });

    group('Text Sanitization', () {
      test('sanitizes HTML characters', () {
        final input = '<script>alert("XSS")</script>';
        final sanitized = InputValidator.sanitizeText(input);
        
        expect(sanitized.contains('<'), isFalse);
        expect(sanitized.contains('>'), isFalse);
      });

      test('removes extra whitespace', () {
        final input = '  test  input  ';
        final sanitized = InputValidator.sanitizeText(input);
        
        expect(sanitized, equals('test  input'));
      });
    });

    group('SQL Injection Detection', () {
      test('detects SQL injection patterns', () {
        expect(InputValidator.containsSqlInjection('SELECT * FROM users'), isTrue);
        expect(InputValidator.containsSqlInjection('DROP TABLE users'), isTrue);
        expect(InputValidator.containsSqlInjection("1' OR '1'='1"), isTrue);
      });

      test('allows safe input', () {
        expect(InputValidator.containsSqlInjection('John Doe'), isFalse);
        expect(InputValidator.containsSqlInjection('123 Main Street'), isFalse);
      });
    });

    group('Amount Validation', () {
      test('valid amounts pass', () {
        expect(InputValidator.validateAmount('100'), isNull);
        expect(InputValidator.validateAmount('50.50'), isNull);
      });

      test('invalid amounts fail', () {
        expect(InputValidator.validateAmount('-50'), isNotNull);
        expect(InputValidator.validateAmount('abc'), isNotNull);
        expect(InputValidator.validateAmount('2000000'), isNotNull);
      });
    });
  });
}
