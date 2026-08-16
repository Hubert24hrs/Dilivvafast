import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:dilivvafast/features/payment/data/repositories/firebase_payment_repository.dart';

import 'payment_repository_test.mocks.dart';

/// Wallet top-up.
///
/// The two things these tests pin down are the ones that were broken:
/// initializePayment used to return the reference it was handed without ever
/// calling the backend, and verification reported nothing about whether the
/// wallet was actually credited.
@GenerateMocks([
  FirebaseFirestore,
  FirebaseFunctions,
  HttpsCallable,
  HttpsCallableResult,
])
void main() {
  late MockFirebaseFunctions functions;
  late MockHttpsCallable callable;
  late FirebasePaymentRepository repository;

  setUp(() {
    functions = MockFirebaseFunctions();
    callable = MockHttpsCallable();
    repository = FirebasePaymentRepository(
      firestore: MockFirebaseFirestore(),
      functions: functions,
    );
  });

  /// Stub the named callable to return [data].
  void stubCallable(String name, Map<String, dynamic> data) {
    final result = MockHttpsCallableResult<Map<String, dynamic>>();
    when(result.data).thenReturn(data);
    when(functions.httpsCallable(name)).thenReturn(callable);
    when(
      callable.call<Map<String, dynamic>>(any),
    ).thenAnswer((_) async => result);
  }

  group('initializePayment', () {
    test('returns the checkout URL and reference from the backend', () async {
      stubCallable('initializePaystackPayment', {
        'success': true,
        'authorizationUrl': 'https://checkout.paystack.com/abc123',
        'reference': 'DVF-user1234-1763000000-x1y2z3',
      });

      final result = await repository.initializePayment(amount: 5000);

      final session = result.getOrElse(
        (failure) => fail('expected a session, got ${failure.message}'),
      );
      expect(session.authorizationUrl, 'https://checkout.paystack.com/abc123');
      expect(session.reference, 'DVF-user1234-1763000000-x1y2z3');
    });

    test(
      'sends only the amount — the backend owns email and reference',
      () async {
        stubCallable('initializePaystackPayment', {
          'authorizationUrl': 'https://checkout.paystack.com/abc123',
          'reference': 'DVF-ref',
        });

        await repository.initializePayment(amount: 2500);

        final captured =
            verify(
                  callable.call<Map<String, dynamic>>(captureAny),
                ).captured.single
                as Map<String, dynamic>;
        expect(captured, {'amount': 2500.0});
      },
    );

    test('fails when the backend returns no checkout link', () async {
      // Previously this path returned the reference string as if it were a
      // URL, and the app tried to open it as a web page.
      stubCallable('initializePaystackPayment', {'success': false});

      final result = await repository.initializePayment(amount: 1000);

      expect(result.isLeft(), isTrue);
    });

    test('surfaces a backend rejection as a failure', () async {
      when(
        functions.httpsCallable('initializePaystackPayment'),
      ).thenReturn(callable);
      when(callable.call<Map<String, dynamic>>(any)).thenThrow(
        FirebaseFunctionsException(
          message: 'Amount must be at least ₦100',
          code: 'invalid-argument',
        ),
      );

      final result = await repository.initializePayment(amount: 5);

      result.fold(
        (failure) => expect(failure.message, contains('at least')),
        (_) => fail('expected a failure'),
      );
    });
  });

  group('verifyPayment', () {
    test('reports the amount credited', () async {
      stubCallable('verifyPaystackPayment', {
        'success': true,
        'amount': 5000,
        'alreadyProcessed': false,
        'message': '₦5,000 credited to wallet',
      });

      final result = await repository.verifyPayment('DVF-ref');

      final verification = result.getOrElse((_) => fail('expected success'));
      expect(verification.amount, 5000);
      expect(verification.alreadyProcessed, isFalse);
    });

    test('flags a reference the backend had already credited', () async {
      // The webhook and this call race by design; whichever loses must not
      // credit again, and the app needs to know so it does not double-count.
      stubCallable('verifyPaystackPayment', {
        'success': true,
        'amount': 5000,
        'alreadyProcessed': true,
        'message': 'This payment was already credited to your wallet',
      });

      final result = await repository.verifyPayment('DVF-ref');

      final verification = result.getOrElse((_) => fail('expected success'));
      expect(verification.alreadyProcessed, isTrue);
      expect(verification.amount, 5000);
    });

    test('passes the reference through unchanged', () async {
      stubCallable('verifyPaystackPayment', {'amount': 100});

      await repository.verifyPayment('DVF-abc-123');

      final captured =
          verify(
                callable.call<Map<String, dynamic>>(captureAny),
              ).captured.single
              as Map<String, dynamic>;
      expect(captured, {'reference': 'DVF-abc-123'});
    });

    test('reports a declined payment as a failure', () async {
      when(
        functions.httpsCallable('verifyPaystackPayment'),
      ).thenReturn(callable);
      when(callable.call<Map<String, dynamic>>(any)).thenThrow(
        FirebaseFunctionsException(
          message: 'Payment not successful: abandoned',
          code: 'failed-precondition',
        ),
      );

      final result = await repository.verifyPayment('DVF-ref');

      result.fold(
        (failure) => expect(failure.message, contains('abandoned')),
        (_) => fail('an abandoned payment must not report success'),
      );
    });
  });

  group('PaymentVerification', () {
    test('defaults are safe when the backend omits fields', () async {
      stubCallable('verifyPaystackPayment', <String, dynamic>{});

      final result = await repository.verifyPayment('DVF-ref');

      final verification = result.getOrElse((_) => fail('expected success'));
      expect(verification.amount, 0);
      expect(verification.alreadyProcessed, isFalse);
      expect(verification.message, isNotEmpty);
    });
  });
}
