import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:fpdart/fpdart.dart';

import 'package:dilivvafast/core/errors/failures.dart';
import 'package:dilivvafast/core/constants/firestore_constants.dart';
import 'package:dilivvafast/features/courier/domain/entities/courier_bid.dart';
import 'package:dilivvafast/features/courier/domain/entities/courier_order_model.dart';
import 'package:dilivvafast/features/courier/domain/repositories/i_courier_repository.dart';

class FirebaseCourierRepository implements ICourierRepository {
  FirebaseCourierRepository({
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  CollectionReference<Map<String, dynamic>> get _couriersRef =>
      _firestore.collection(FirestoreConstants.couriers);

  @override
  Future<Either<Failure, CourierOrderModel>> createOrder(
    CourierOrderModel order,
  ) async {
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
    String orderId,
  ) async {
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
        .where(
          FirestoreConstants.fieldStatus,
          whereIn: ['pending', 'accepted', 'picked_up', 'in_transit'],
        )
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
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => CourierOrderModel.fromFirestore(doc))
              .toList(),
        );
  }

  @override
  Stream<List<CourierOrderModel>> watchDriverOrders(String driverId) {
    return _couriersRef
        .where(FirestoreConstants.fieldDriverId, isEqualTo: driverId)
        .orderBy(FirestoreConstants.fieldCreatedAt, descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => CourierOrderModel.fromFirestore(doc))
              .toList(),
        );
  }

  @override
  Stream<List<CourierOrderModel>> watchPendingOrders() {
    return _couriersRef
        .where(FirestoreConstants.fieldStatus, isEqualTo: 'pending')
        .orderBy(FirestoreConstants.fieldCreatedAt, descending: false)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => CourierOrderModel.fromFirestore(doc))
              .toList(),
        );
  }

  @override
  Stream<List<CourierOrderModel>> watchAllOrders() {
    return _couriersRef
        .orderBy(FirestoreConstants.fieldCreatedAt, descending: true)
        .limit(100)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => CourierOrderModel.fromFirestore(doc))
              .toList(),
        );
  }

  @override
  Future<Either<Failure, Unit>> updateOrderStatus(
    String orderId,
    OrderStatus newStatus,
  ) async {
    try {
      final doc = await _couriersRef.doc(orderId).get();
      if (!doc.exists) {
        return const Left(FirestoreFailure('Order not found'));
      }

      final currentOrder = CourierOrderModel.fromFirestore(doc);
      if (!currentOrder.canTransitionTo(newStatus)) {
        return Left(
          ValidationFailure(
            'Cannot transition from ${currentOrder.status.name} to ${newStatus.name}',
          ),
        );
      }

      final updateData = <String, dynamic>{
        // wireValue, not .name — see OrderStatusWire.
        FirestoreConstants.fieldStatus: newStatus.wireValue,
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

  // ── Price negotiation ────────────────────────────────────────────────────

  CollectionReference<Map<String, dynamic>> _bidsRef(String orderId) =>
      _couriersRef.doc(orderId).collection(FirestoreConstants.bids);

  @override
  Stream<List<CourierBid>> watchBids(String orderId) {
    return _bidsRef(
      orderId,
    ).where('status', isEqualTo: BidStatus.open.name).snapshots().map((snap) {
      final bids = snap.docs
          .map(CourierBid.fromFirestore)
          .where((b) => b.isEnriched)
          .toList();
      bids.sort((a, b) => a.amount.compareTo(b.amount));
      return bids;
    });
  }

  @override
  Stream<CourierBid?> watchMyBid(String orderId, String driverId) {
    return _bidsRef(orderId)
        .doc(driverId)
        .snapshots()
        .map((doc) => doc.exists ? CourierBid.fromFirestore(doc) : null);
  }

  @override
  Future<Either<Failure, Unit>> placeBid({
    required String orderId,
    required String driverId,
    required double amount,
    int? etaMinutes,
  }) async {
    try {
      // Only these keys are client-writable. The driver's name, rating and
      // vehicle are filled in server-side from their own record.
      await _bidsRef(orderId).doc(driverId).set({
        'driverId': driverId,
        'amount': amount,
        'status': BidStatus.open.name,
        'etaMinutes': ?etaMinutes,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return const Right(unit);
    } on FirebaseException catch (e) {
      return Left(
        FirestoreFailure(
          e.code == 'permission-denied'
              ? 'This request is no longer taking offers.'
              : 'Could not send your offer. Please try again.',
        ),
      );
    } catch (e) {
      return Left(FirestoreFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> withdrawBid(
    String orderId,
    String driverId,
  ) async {
    try {
      await _bidsRef(orderId).doc(driverId).delete();
      return const Right(unit);
    } catch (e) {
      return Left(FirestoreFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> declineBid(
    String orderId,
    String driverId,
  ) async {
    try {
      await _bidsRef(
        orderId,
      ).doc(driverId).update({'status': BidStatus.declined.name});
      return const Right(unit);
    } catch (e) {
      return Left(FirestoreFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> acceptBid(
    String orderId,
    String driverId,
  ) async {
    final callable = _functions.httpsCallable('acceptBid');
    final payload = {'orderId': orderId, 'driverId': driverId};
    try {
      try {
        await callable.call<Map<String, dynamic>>(payload);
      } on FirebaseFunctionsException catch (e) {
        // 'aborted' means the transaction lost a race under contention, not
        // that the offer was refused. One retry is safe: the server re-checks
        // everything, so if another offer won in the meantime this second
        // attempt fails with "already has a courier" instead.
        if (e.code != 'aborted') rethrow;
        await Future<void>.delayed(const Duration(milliseconds: 400));
        await callable.call<Map<String, dynamic>>(payload);
      }
      return const Right(unit);
    } on FirebaseFunctionsException catch (e) {
      return Left(
        FirestoreFailure(e.message ?? 'Could not accept that offer.'),
      );
    } catch (e) {
      return Left(FirestoreFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, double>> raiseOffer(
    String orderId,
    double amount,
  ) async {
    try {
      final result = await _functions
          .httpsCallable('raiseOffer')
          .call<Map<String, dynamic>>({'orderId': orderId, 'amount': amount});
      return Right((result.data['offeredFare'] as num).toDouble());
    } on FirebaseFunctionsException catch (e) {
      return Left(FirestoreFailure(e.message ?? 'Could not raise your offer.'));
    } catch (e) {
      return Left(FirestoreFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> updateProofOfDelivery(
    String orderId,
    String imageUrl,
  ) async {
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
    String orderId,
    int rating,
    String? comment,
  ) async {
    if (rating < 1 || rating > 5) {
      return const Left(FirestoreFailure('Choose between 1 and 5 stars.'));
    }
    try {
      final orderRef = _couriersRef.doc(orderId);
      final order = await orderRef.get();
      final driverId = order.data()?['driverId'] as String?;
      final userId = order.data()?['userId'] as String?;
      if (driverId == null || userId == null) {
        return const Left(FirestoreFailure('This delivery has no courier.'));
      }

      // Two writes, one batch. The order keeps the customer's own record of
      // the rating; ratings/{orderId} is what onRatingCreated averages into
      // the courier's profile. Before this, only the order was written, so
      // the trigger never fired and every courier stayed unrated. Keying the
      // rating by order id makes it one rating per delivery.
      final batch = _firestore.batch();
      batch.update(orderRef, {
        'rating': rating,
        'ratingComment': comment,
        FirestoreConstants.fieldUpdatedAt: FieldValue.serverTimestamp(),
      });
      batch
          .set(_firestore.collection(FirestoreConstants.ratings).doc(orderId), {
            'orderId': orderId,
            'userId': userId,
            'driverId': driverId,
            'rating': rating,
            'comment': comment,
            FirestoreConstants.fieldCreatedAt: FieldValue.serverTimestamp(),
          });
      await batch.commit();
      return const Right(unit);
    } on FirebaseException catch (e) {
      return Left(
        FirestoreFailure(
          e.code == 'permission-denied'
              ? 'You have already rated this delivery.'
              : 'Could not save your rating. Please try again.',
        ),
      );
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
    String trackingCode,
  ) async {
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
        query = query.where(
          FirestoreConstants.fieldStatus,
          isEqualTo: statusFilter.wireValue,
        );
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
