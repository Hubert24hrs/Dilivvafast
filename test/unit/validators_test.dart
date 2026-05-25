import 'package:fast_delivery/core/utils/validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Validators', () {
    group('email', () {
      test('returns error for empty email', () {
        expect(Validators.email(''), 'Email is required');
        expect(Validators.email(null), 'Email is required');
      });

      test('returns error for invalid email format', () {
        expect(Validators.email('test'), 'Please enter a valid email address');
        expect(Validators.email('test@'), 'Please enter a valid email address');
        expect(Validators.email('@test.com'), 'Please enter a valid email address');
        expect(Validators.email('test.com'), 'Please enter a valid email address');
      });

      test('returns null for valid email', () {
        expect(Validators.email('test@example.com'), null);
        expect(Validators.email('user.name@domain.co.uk'), null);
        expect(Validators.email('user+tag@example.org'), null);
      });
    });

    group('password', () {
      test('returns error for empty password', () {
        expect(Validators.password(''), 'Password is required');
        expect(Validators.password(null), 'Password is required');
      });

      test('returns error for password less than 8 characters', () {
        expect(Validators.password('abc123'), 'Password must be at least 8 characters');
        expect(Validators.password('Pass1'), 'Password must be at least 8 characters');
      });

      test('returns error for password without letters', () {
        expect(Validators.password('12345678'), 'Password must contain at least one letter');
      });

      test('returns error for password without numbers', () {
        expect(Validators.password('abcdefgh'), 'Password must contain at least one number');
      });

      test('returns null for valid password', () {
        expect(Validators.password('Password1'), null);
        expect(Validators.password('MySecure123'), null);
        expect(Validators.password('Test12345'), null);
      });
    });

    group('confirmPassword', () {
      test('returns error for empty confirmation', () {
        expect(Validators.confirmPassword('', 'password'), 'Please confirm your password');
        expect(Validators.confirmPassword(null, 'password'), 'Please confirm your password');
      });

      test('returns error when passwords do not match', () {
        expect(Validators.confirmPassword('pass1234', 'pass5678'), 'Passwords do not match');
      });

      test('returns null when passwords match', () {
        expect(Validators.confirmPassword('Password123', 'Password123'), null);
      });
    });

    group('phoneNumber', () {
      test('returns error for empty phone number', () {
        expect(Validators.phoneNumber(''), 'Phone number is required');
        expect(Validators.phoneNumber(null), 'Phone number is required');
      });

      test('returns error for invalid Nigerian phone number', () {
        expect(Validators.phoneNumber('1234567890'), 'Please enter a valid Nigerian phone number');
        expect(Validators.phoneNumber('+1234567890'), 'Please enter a valid Nigerian phone number');
      });

      test('returns null for valid Nigerian phone numbers', () {
        expect(Validators.phoneNumber('+2348012345678'), null);
        expect(Validators.phoneNumber('2348012345678'), null);
        expect(Validators.phoneNumber('08012345678'), null);
        expect(Validators.phoneNumber('09012345678'), null);
        expect(Validators.phoneNumber('07012345678'), null);
      });
    });

    group('required', () {
      test('returns error for empty value', () {
        expect(Validators.required(''), 'This field is required');
        expect(Validators.required('   '), 'This field is required');
        expect(Validators.required(null), 'This field is required');
      });

      test('returns null for non-empty value', () {
        expect(Validators.required('value'), null);
      });

      test('uses custom field name in error message', () {
        expect(Validators.required('', 'Username'), 'Username is required');
      });
    });

    group('minLength', () {
      test('returns error for value less than minimum', () {
        expect(Validators.minLength('ab', 3), 'This field must be at least 3 characters');
      });

      test('returns null for value meeting minimum', () {
        expect(Validators.minLength('abc', 3), null);
        expect(Validators.minLength('abcd', 3), null);
      });
    });

    group('maxLength', () {
      test('returns error for value exceeding maximum', () {
        expect(Validators.maxLength('abcdef', 5), 'This field cannot exceed 5 characters');
      });

      test('returns null for value within maximum', () {
        expect(Validators.maxLength('abc', 5), null);
        expect(Validators.maxLength('abcde', 5), null);
      });
    });

    group('numeric', () {
      test('returns error for non-numeric value', () {
        expect(Validators.numeric('abc'), 'This field must be a valid number');
        expect(Validators.numeric('12.34.56'), 'This field must be a valid number');
      });

      test('returns null for numeric values', () {
        expect(Validators.numeric('123'), null);
        expect(Validators.numeric('12.34'), null);
        expect(Validators.numeric('-123'), null);
      });
    });

    group('positiveNumber', () {
      test('returns error for non-positive numbers', () {
        expect(Validators.positiveNumber('0'), 'Amount must be greater than zero');
        expect(Validators.positiveNumber('-10'), 'Amount must be greater than zero');
      });

      test('returns null for positive numbers', () {
        expect(Validators.positiveNumber('1'), null);
        expect(Validators.positiveNumber('100.50'), null);
      });
    });

    group('name', () {
      test('returns error for empty name', () {
        expect(Validators.name(''), 'Name is required');
      });

      test('returns error for name with numbers or special chars', () {
        expect(Validators.name('John123'), "Name can only contain letters, spaces, and hyphens");
        expect(Validators.name('John@Doe'), isNotNull);
      });

      test('returns null for valid names', () {
        expect(Validators.name('John'), null);
        expect(Validators.name('John Doe'), null);
        expect(Validators.name("O'Brien"), null);
        expect(Validators.name('Mary-Jane'), null);
      });
    });

    group('combine', () {
      test('returns first error from combined validators', () {
        final result = Validators.combine('', [
          Validators.required,
          Validators.email,
        ]);
        expect(result, 'This field is required');
      });

      test('returns null if all validators pass', () {
        final result = Validators.combine('test@example.com', [
          Validators.required,
          Validators.email,
        ]);
        expect(result, null);
      });
    });
  });
}
