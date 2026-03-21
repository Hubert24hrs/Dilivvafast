import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fpdart/fpdart.dart';

import 'package:fast_delivery/core/errors/failures.dart';
import 'package:fast_delivery/core/constants/firestore_constants.dart';
import 'package:fast_delivery/features/courier/domain/entities/courier_order_model.dart';
import 'package:fast_delivery/features/courier/domain/repositories/i_courier_repository.dart';

class FirebaseCourierRepository implements ICourierRepository {
  FirebaseCourierRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _couriersRef =>
      _firestore.collection(FirestoreConstants.couriers);

  @override
  Future<Either<Failure, CourierOrderModel>> createOrder(
      CourierOrderModel order) async {
    try {
      final trackingCode = _generateTrackingCode();
      final now = DateTime.now();
      final orderWithCode = order.copyWith(
        trackingCode: trackingCode,
        createdAt: now,
        updatedAt: now,
      );

      final docRef = await _couriersRef.add(orderWithCode.toFirestore());
      final doc = await docRef.get();
      return Right(CourierOrderModel.fromFirestore(doc));
    } catch (e) {
      return Left(FirestoreFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, CourierOrderModel>> getOrderById(
      String orderId) async {
    try {
      final doc = await _couriersRef.doc(orderId).get();
      if (!doc.exists) {
        return const Left(FirestoreFailure('Order not found'));
      }
      return Right(CourierOrderModel.fromFirestore(doc));
    } catch (e) {
      return Left(FirestoreFailure(e.toString()));
    }
  }

  @override
  Stream<CourierOrderModel?> watchOrder(String orderId) {
    return _couriersRef.doc(orderId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return CourierOrderModel.fromFirestore(doc);
    });
  }

  @override
  Stream<CourierOrderModel?> watchActiveOrder(String userId) {
    return _couriersRef
        .where(FirestoreConstants.fieldUserId, isEqualTo: userId)
        .where(FirestoreConstants.fieldStatus,
            whereIn: ['pending', 'accepted', 'picked_up', 'in_transit'])
        .limit(1)
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isEmpty) return null;
          return CourierOrderModel.fromFirestore(snapshot.docs.first);
        });
  }

  @override
  Stream<List<CourierOrderModel>> watchCustomerOrders(String userId) {
    return _couriersRef
        .where(FirestoreConstants.fieldUserId, isEqualTo: userId)
        .orderBy(FirestoreConstants.fieldCreatedAt, descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CourierOrderModel.fromFirestore(doc))
            .toList());
  }

  @override
  Stream<List<CourierOrderModel>> watchDriverOrders(String driverId) {
    return _couriersRef
        .where(FirestoreConstants.fieldDriverId, isEqualTo: driverId)
        .orderBy(FirestoreConstants.fieldCreatedAt, descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CourierOrderModel.fromFirestore(doc))
            .toList());
  }

  @override
  Stream<List<CourierOrderModel>> watchPendingOrders() {
    return _couriersRef
        .where(FirestoreConstants.fieldStatus, isEqualTo: 'pending')
        .orderBy(FirestoreConstants.fieldCreatedAt, descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CourierOrderModel.fromFirestore(doc))
            .toList());
  }

  @override
  Stream<List<CourierOrderModel>> watchAllOrders() {
    return _couriersRef
        .orderBy(FirestoreConstants.fieldCreatedAt, descending: true)
        .limit(100)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CourierOrderModel.fromFirestore(doc))
            .toList());
  }

  @override
  Future<Either<Failure, Unit>> updateOrderStatus(
      String orderId, OrderStatus newStatus) async {
    try {
      final doc = await _couriersRef.doc(orderId).get();
      if (!doc.exists) {
        return const Left(FirestoreFailure('Order not found'));
      }

      final currentOrder = CourierOrderModel.fromFirestore(doc);
      if (!currentOrder.canTransitionTo(newStatus)) {
        return Left(ValidationFailure(
            'Cannot transition from ${currentOrder.status.name} to ${newStatus.name}'));
      }

      final updateData = <String, dynamic>{
        FirestoreConstants.fieldStatus: newStatus.name,
        FirestoreConstants.fieldUpdatedAt: FieldValue.serverTimestamp(),
      };

      if (newStatus == OrderStatus.pickedUp) {
        updateData['pickedUpAt'] = FieldValue.serverTimestamp();
      } else if (newStatus == OrderStatus.delivered) {
        updateData['deliveredAt'] = FieldValue.serverTimestamp();
      }

      await _couriersRef.doc(orderId).update(updateData);
      return const Right(unit);
    } catch (e) {
      return Left(FirestoreFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> assignDriver(
      String orderId, String driverId) async {
    try {
      await _couriersRef.doc(orderId).update({
        FirestoreConstants.fieldDriverId: driverId,
        FirestoreConstants.fieldStatus: OrderStatus.accepted.name,
        FirestoreConstants.fieldUpdatedAt: FieldValue.serverTimestamp(),
      });
      return const Right(unit);
    } catch (e) {
      return Left(FirestoreFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> updateProofOfDelivery(
      String orderId, String imageUrl) async {
    try {
      await _couriersRef.doc(orderId).update({
        'proofOfDeliveryUrl': imageUrl,
        FirestoreConstants.fieldUpdatedAt: FieldValue.serverTimestamp(),
      });
      return const Right(unit);
    } catch (e) {
      return Left(FirestoreFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> rateOrder(
      String orderId, int rating, String? comment) async {
    try {
      await _couriersRef.doc(orderId).update({
        'rating': rating,
        'ratingComment': comment,
        FirestoreConstants.fieldUpdatedAt: FieldValue.serverTimestamp(),
      });
      return const Right(unit);
    } catch (e) {
      return Left(FirestoreFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> cancelOrder(String orderId) async {
    return updateOrderStatus(orderId, OrderStatus.cancelled);
  }

  @override
  Future<Either<Failure, CourierOrderModel?>> getOrderByTrackingCode(
      String trackingCode) async {
    try {
      final query = await _couriersRef
          .where('trackingCode', isEqualTo: trackingCode)
          .limit(1)
          .get();
      if (query.docs.isEmpty) return const Right(null);
      return Right(CourierOrderModel.fromFirestore(query.docs.first));
    } catch (e) {
      return Left(FirestoreFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<CourierOrderModel>>> getPaginatedOrders({
    required String userId,
    OrderStatus? statusFilter,
    int limit = 20,
    String? lastDocumentId,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _couriersRef
          .where(FirestoreConstants.fieldUserId, isEqualTo: userId)
          .orderBy(FirestoreConstants.fieldCreatedAt, descending: true)
          .limit(limit);

      if (statusFilter != null) {
        query = query.where(FirestoreConstants.fieldStatus,
            isEqualTo: statusFilter.name);
      }

      if (lastDocumentId != null) {
        final lastDoc = await _couriersRef.doc(lastDocumentId).get();
        if (lastDoc.exists) {
          query = query.startAfterDocument(lastDoc);
        }
      }

      final snapshot = await query.get();
      final orders = snapshot.docs
          .map((doc) => CourierOrderModel.fromFirestore(doc))
          .toList();
      return Right(orders);
    } catch (e) {
      return Left(FirestoreFailure(e.toString()));
    }
  }

  String _generateTrackingCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random.secure();
    return String.fromCharCodes(
      Iterable.generate(
        6,
        (_) => chars.codeUnitAt(random.nextInt(chars.length)),
      ),
    );
  }
}
