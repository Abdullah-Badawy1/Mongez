import 'package:flutter_test/flutter_test.dart';
import 'package:mongez/core/validators.dart';

void main() {
  group('Validators.required', () {
    final v = Validators.required('Required');
    test('null and empty fail', () {
      expect(v(null), 'Required');
      expect(v(''), 'Required');
      expect(v('   '), 'Required');
    });
    test('non-empty passes', () {
      expect(v('hi'), null);
    });
  });

  group('Validators.email', () {
    final v = Validators.email('Bad email');
    test('valid emails pass', () {
      expect(v('a@b.co'), null);
      expect(v('first.last+tag@example.com'), null);
    });
    test('invalid emails fail', () {
      expect(v('not-an-email'), 'Bad email');
      expect(v('@example.com'), 'Bad email');
    });
    test('empty value is treated as optional', () {
      expect(v(''), null);
      expect(v(null), null);
    });
  });

  group('Validators.phone', () {
    final v = Validators.phone('Bad phone');
    test('common Egyptian numbers pass', () {
      expect(v('+201234567890'), null);
      expect(v('01234567890'), null);
      expect(v('+1 (555) 123-4567'), null);
    });
    test('garbage is rejected', () {
      expect(v(''), 'Bad phone');
      expect(v('abc'), 'Bad phone');
      expect(v('123'), 'Bad phone'); // too short
    });
  });

  group('Validators.compose', () {
    final v = Validators.compose([
      Validators.required('Required'),
      Validators.minLength(3, 'Min 3'),
    ]);
    test('returns the first failing message', () {
      expect(v(''), 'Required');
      expect(v('ab'), 'Min 3');
      expect(v('abcd'), null);
    });
  });

  group('Validators.stars', () {
    test('accepts 1-5', () {
      expect(Validators.stars(1), null);
      expect(Validators.stars(5), null);
    });
    test('rejects out-of-range', () {
      expect(Validators.stars(0), isNotNull);
      expect(Validators.stars(6), isNotNull);
      expect(Validators.stars(null), isNotNull);
    });
  });
}
