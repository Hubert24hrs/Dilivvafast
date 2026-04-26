import 'package:fpdart/fpdart.dart';
import 'package:dilivvafast/core/errors/failures.dart';
import 'package:dilivvafast/features/courier/domain/entities/courier_order_model.dart';

/// Abstract repository for courier order operations.
abstract class ICourierRepository {
  /// Create a new courier order
  Future<Either<Failure, CourierOrderModel>> createOrder(
      CourierOrderModel order);

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
      String orderId, OrderStatus newStatus);

  /// Assign driver to order
  Future<Either<Failure, Unit>> assignDriver(
      String orderId, String driverId);

  /// Update proof of delivery
  Future<Either<Failure, Unit>> updateProofOfDelivery(
      String orderId, String imageUrl);

  /// Rate an order
  Future<Either<Failure, Unit>> rateOrder(
      String orderId, int rating, String? comment);

  /// Cancel an order
  Future<Either<Failure, Unit>> cancelOrder(String orderId);

  /// Get order by tracking code
  Future<Either<Failure, CourierOrderModel?>> getOrderByTrackingCode(
      String trackingCode);

  /// Get paginated orders for a user
  Future<Either<Failure, List<CourierOrderModel>>> getPaginatedOrders({
    required String userId,
    OrderStatus? statusFilter,
    int limit = 20,
    String? lastDocumentId,
  });
}
