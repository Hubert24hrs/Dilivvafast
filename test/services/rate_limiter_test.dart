import 'package:fast_delivery/core/security/rate_limiter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RateLimiter Tests', () {
    late RateLimiter rateLimiter;

    setUp(() {
      rateLimiter = RateLimiter(
        window: const Duration(seconds: 10),
        maxRequests: 3,
      );
    });

    test('allows requests under limit', () {
      expect(rateLimiter.isAllowed('user1'), isTrue);
      expect(rateLimiter.isAllowed('user1'), isTrue);
      expect(rateLimiter.isAllowed('user1'), isTrue);
    });

    test('blocks requests over limit', () {
      rateLimiter.isAllowed('user2');
      rateLimiter.isAllowed('user2');
      rateLimiter.isAllowed('user2');
      
      expect(rateLimiter.isAllowed('user2'), isFalse);
    });

    test('tracks different identifiers separately', () {
      rateLimiter.isAllowed('user3');
      rateLimiter.isAllowed('user3');
      rateLimiter.isAllowed('user3');
      
      expect(rateLimiter.isAllowed('user3'), isFalse);
      expect(rateLimiter.isAllowed('user4'), isTrue);
    });

    test('getRemainingRequests returns correct count', () {
      rateLimiter.isAllowed('user5');
      expect(rateLimiter.getRemainingRequests('user5'), equals(2));
      
      rateLimiter.isAllowed('user5');
      expect(rateLimiter.getRemainingRequests('user5'), equals(1));
    });

    test('clearHistory resets for identifier', () {
      rateLimiter.isAllowed('user6');
      rateLimiter.isAllowed('user6');
      rateLimiter.isAllowed('user6');
      
      expect(rateLimiter.isAllowed('user6'), isFalse);
      
      rateLimiter.clearHistory('user6');
      expect(rateLimiter.isAllowed('user6'), isTrue);
    });
  });
}
