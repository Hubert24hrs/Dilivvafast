import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fpdart/fpdart.dart';

import 'package:fast_delivery/core/errors/failures.dart';
import 'package:fast_delivery/core/constants/firestore_constants.dart';
import 'package:fast_delivery/features/investor/domain/entities/bike_model.dart';
import 'package:fast_delivery/features/investor/domain/entities/hp_agreement_model.dart';
import 'package:fast_delivery/features/investor/domain/entities/investor_model.dart';
import 'package:fast_delivery/features/investor/domain/entities/investor_earnings_model.dart';
import 'package:fast_delivery/features/investor/domain/repositories/i_investor_repository.dart';

class FirebaseInvestorRepository implements IInvestorRepository {
  FirebaseInvestorRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  @override
  Stream<InvestorModel?> watchInvestorProfile(String userId) {
    return _firestore
        .collection(FirestoreConstants.investors)
        .doc(userId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return null;
      return InvestorModel.fromFirestore(doc);
    });
  }

  @override
  Stream<List<BikeModel>> watchInvestorBikes(String userId) {
    return _firestore
        .collection(FirestoreConstants.bikes)
        .where('investorId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => BikeModel.fromFirestore(doc)).toList());
  }

  @override
  Stream<List<BikeModel>> watchAvailableBikes() {
    return _firestore
        .collection(FirestoreConstants.bikes)
        .where(FirestoreConstants.fieldStatus, isEqualTo: 'pending_funding')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => BikeModel.fromFirestore(doc)).toList());
  }

  @override
  Stream<List<HPAgreementModel>> watchInvestorAgreements(String userId) {
    return _firestore
        .collection(FirestoreConstants.hpAgreements)
        .where('investorId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => HPAgreementModel.fromFirestore(doc))
            .toList());
  }

  @override
  Stream<List<InvestorEarningsModel>> watchInvestorEarnings(String userId) {
    return _firestore
        .collection(FirestoreConstants.investorEarnings)
        .where('investorId', isEqualTo: userId)
        .orderBy(FirestoreConstants.fieldCreatedAt, descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => InvestorEarningsModel.fromFirestore(doc))
            .toList());
  }

  @override
  Stream<List<InvestorWithdrawalModel>> watchWithdrawals(String userId) {
    return _firestore
        .collection(FirestoreConstants.investorWithdrawals)
        .where('investorId', isEqualTo: userId)
        .orderBy(FirestoreConstants.fieldCreatedAt, descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => InvestorWithdrawalModel.fromFirestore(doc))
            .toList());
  }

  @override
  Future<Either<Failure, Unit>> fundBike(
      String bikeId, String investorId) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final bikeRef =
            _firestore.collection(FirestoreConstants.bikes).doc(bikeId);
        final bikeDoc = await transaction.get(bikeRef);

        if (!bikeDoc.exists) throw Exception('Bike not found');
        final bike = BikeModel.fromFirestore(bikeDoc);
        if (bike.status != BikeStatus.pendingFunding) {
          throw Exception('Bike is no longer available for funding');
        }

        // Update bike status and assign investor
        transaction.update(bikeRef, {
          'investorId': investorId,
          FirestoreConstants.fieldStatus: BikeStatus.funded.name,
        });

        // Create/update investor profile
        final investorRef = _firestore
            .collection(FirestoreConstants.investors)
            .doc(investorId);
        final investorDoc = await transaction.get(investorRef);

        if (investorDoc.exists) {
          transaction.update(investorRef, {
            'totalInvested': FieldValue.increment(bike.purchasePrice),
            'activeBikes': FieldValue.increment(1),
          });
        } else {
          transaction.set(investorRef, InvestorModel(
            id: investorId,
            userId: investorId,
            totalInvested: bike.purchasePrice,
            activeBikes: 1,
            createdAt: DateTime.now(),
          ).toFirestore());
        }
      });

      return const Right(unit);
    } catch (e) {
      return Left(FirestoreFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> requestWithdrawal({
    required String investorId,
    required double amount,
    required String bankName,
    required String accountNumber,
    required String accountName,
  }) async {
    try {
      final withdrawal = InvestorWithdrawalModel(
        id: '',
        investorId: investorId,
        amount: amount,
        bankName: bankName,
        accountNumber: accountNumber,
        accountName: accountName,
        status: 'pending',
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection(FirestoreConstants.investorWithdrawals)
          .add(withdrawal.toFirestore());

      return const Right(unit);
    } catch (e) {
      return Left(FirestoreFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> isInvestor(String userId) async {
    try {
      final doc = await _firestore
          .collection(FirestoreConstants.investors)
          .doc(userId)
          .get();
      return Right(doc.exists);
    } catch (e) {
      return Left(FirestoreFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, BikeModel>> getBikeById(String bikeId) async {
    try {
      final doc = await _firestore
          .collection(FirestoreConstants.bikes)
          .doc(bikeId)
          .get();
      if (!doc.exists) {
        return const Left(FirestoreFailure('Bike not found'));
      }
      return Right(BikeModel.fromFirestore(doc));
    } catch (e) {
      return Left(FirestoreFailure(e.toString()));
    }
  }
}
