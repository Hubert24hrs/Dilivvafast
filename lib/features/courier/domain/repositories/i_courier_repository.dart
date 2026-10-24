import 'package:fpdart/fpdart.dart';
import 'package:dilivvafast/core/errors/failures.dart';
import 'package:dilivvafast/features/courier/domain/entities/courier_bid.dart';
import 'package:dilivvafast/features/courier/domain/entities/courier_order_model.dart';

/// Abstract repository for courier order operations.
abstract class ICourierRepository {
  /// Create a new courier order
  Future<Either<Failure, CourierOrderModel>> createOrder(
    CourierOrderModel order,
  );

  /// Get order by ID (one-time)
  Future<Either<Failure, CourierOrderModel>> getOrderById(String orderId);

  /// Stream a single order for real-time updates
  Stream<CourierOrderModel?> watchOrder(String orderId);

  /// Stream active order for a customer
  Stream<CourierOrderModel?> watchActiveOrder(String userId);

  /// Stream orders by customer
  Stream<List<CourierOrderModel>> watchCustomerOrders(String userId);

  /// Stream orders by driver
  Stream<List<CourierOrderModel>> watchDriverOrders(String driverId);

  /// Stream pending orders (for driver assignment)
  Stream<List<CourierOrderModel>> watchPendingOrders();

  /// Stream all orders (admin)
  Stream<List<CourierOrderModel>> watchAllOrders();

  /// Update order status with validation
  Future<Either<Failure, Unit>> updateOrderStatus(
    String orderId,
    OrderStatus newStatus,
  );

  // ── Price negotiation (inDrive-style) ────────────────────────────────────
  //
  // A driver never assigns themselves to a job. They place an offer; the
  // customer picks one; the server assigns. That replaces the old
  // `assignDriver`, which let any approved driver claim any pending job at
  // whatever price was on it.

  /// Live offers on one request, cheapest first. Customer view.
  Stream<List<CourierBid>> watchBids(String orderId);

  /// The calling driver's own offer on a request, if any.
  Stream<CourierBid?> watchMyBid(String orderId, String driverId);

  /// Make or revise an offer. Must be at least the customer's current offer.
  Future<Either<Failure, Unit>> placeBid({
    required String orderId,
    required String driverId,
    required double amount,
    int? etaMinutes,
  });

  /// Take an offer back before the customer answers.
  Future<Either<Failure, Unit>> withdrawBid(String orderId, String driverId);

  /// Customer turns an offer down.
  Future<Either<Failure, Unit>> declineBid(String orderId, String driverId);

  /// Customer accepts an offer. Server-side and atomic: assigns the driver,
  /// fixes the price, and closes every other offer.
  Future<Either<Failure, Unit>> acceptBid(String orderId, String driverId);

  /// Customer raises their own offer while waiting. Returns the new offer
  /// as stored by the server, which may have been clamped.
  Future<Either<Failure, double>> raiseOffer(String orderId, double amount);

  /// Update proof of delivery
  Future<Either<Failure, Unit>> updateProofOfDelivery(
    String orderId,
    String imageUrl,
  );

  /// Rate an order
  Future<Either<Failure, Unit>> rateOrder(
    String orderId,
    int rating,
    String? comment,
  );

  /// Cancel an order
  Future<Either<Failure, Unit>> cancelOrder(String orderId);

  /// Get order by tracking code
  Future<Either<Failure, CourierOrderModel?>> getOrderByTrackingCode(
    String trackingCode,
  );

  /// Get paginated orders for a user
  Future<Either<Failure, List<CourierOrderModel>>> getPaginatedOrders({
    required String userId,
    OrderStatus? statusFilter,
    int limit = 20,
    String? lastDocumentId,
  });
}
