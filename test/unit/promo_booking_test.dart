import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import 'package:dilivvafast/core/errors/failures.dart';
import 'package:dilivvafast/core/providers/providers.dart';
import 'package:dilivvafast/features/booking/presentation/controllers/courier_booking_controller.dart';
import 'package:dilivvafast/features/courier/domain/entities/courier_order_model.dart';
import 'package:dilivvafast/features/courier/domain/repositories/i_courier_repository.dart';

/// A promo applied on the Promotions screen has to reach the order, because
/// only the server (`onCourierCreated`) redeems it. It used to stop at a
/// provider nothing read, so no order ever carried a code.

class _CapturingRepo implements ICourierRepository {
  final created = <CourierOrderModel>[];

  @override
  Future<Either<Failure, CourierOrderModel>> createOrder(
    CourierOrderModel order,
  ) async {
    created.add(order);
    return Right(order.copyWith(id: 'order-${created.length}'));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _CapturingRepo repo;
  late ProviderContainer container;

  setUp(() {
    repo = _CapturingRepo();
    container = ProviderContainer(
      overrides: [
        currentUserIdProvider.overrideWithValue('customer-1'),
        courierRepositoryProvider.overrideWithValue(repo),
      ],
    );
    addTearDown(container.dispose);

    container.read(courierBookingControllerProvider.notifier)
      ..setPickup('1 Marina, Lagos', 6.4541, 3.3947)
      ..setDropoff('12 Awolowo Rd, Ikoyi', 6.4478, 3.4342);
  });

  CourierBookingController controller() =>
      container.read(courierBookingControllerProvider.notifier);

  test('an applied code is sent with the order, normalised', () async {
    controller().setPromoCode('  welcome500 ');
    expect(
      container.read(courierBookingControllerProvider).promoCode,
      'WELCOME500',
    );

    await controller().submitOrder();
    expect(repo.created.single.promoCode, 'WELCOME500');
  });

  test('the code is not carried into the next request', () async {
    controller().setPromoCode('WELCOME500');
    await controller().submitOrder();
    expect(container.read(courierBookingControllerProvider).promoCode, isEmpty);

    await controller().submitOrder();
    expect(repo.created.last.promoCode, isNull);
  });

  test('no code means no promoCode on the order', () async {
    await controller().submitOrder();
    expect(repo.created.single.promoCode, isNull);
  });
}
