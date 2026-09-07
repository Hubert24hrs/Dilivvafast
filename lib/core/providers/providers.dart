/// Centralized Riverpod provider definitions.
/// Follows strict layering: Firebase → Repository → Stream → State
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Services
import 'package:dilivvafast/core/services/location_tracking_service.dart';
import 'package:dilivvafast/core/infrastructure/notification/fcm_service.dart';

// Repository interfaces
import 'package:dilivvafast/features/auth/domain/repositories/i_auth_repository.dart';
import 'package:dilivvafast/features/auth/domain/repositories/i_user_repository.dart';
import 'package:dilivvafast/features/courier/domain/repositories/i_courier_repository.dart';
import 'package:dilivvafast/features/payment/domain/repositories/i_payment_repository.dart';
import 'package:dilivvafast/features/investor/domain/repositories/i_investor_repository.dart';

// Firebase implementations
import 'package:dilivvafast/features/auth/data/repositories/firebase_auth_repository.dart';
import 'package:dilivvafast/features/auth/data/repositories/firebase_user_repository.dart';
import 'package:dilivvafast/features/courier/data/repositories/firebase_courier_repository.dart';
import 'package:dilivvafast/features/payment/data/repositories/firebase_payment_repository.dart';
import 'package:dilivvafast/features/investor/data/repositories/firebase_investor_repository.dart';

// Models
import 'package:dilivvafast/features/auth/domain/entities/user_model.dart';
import 'package:dilivvafast/features/courier/domain/entities/courier_order_model.dart';
import 'package:dilivvafast/features/payment/domain/entities/transaction_model.dart';
import 'package:dilivvafast/features/investor/domain/entities/bike_model.dart';
import 'package:dilivvafast/features/investor/domain/entities/investor_model.dart';
import 'package:dilivvafast/features/investor/domain/entities/hp_agreement_model.dart';
import 'package:dilivvafast/features/investor/domain/entities/investor_earnings_model.dart';
import 'package:dilivvafast/core/domain/entities/notification_model.dart';
import 'package:dilivvafast/core/domain/entities/driver_presence.dart';

// Core services
import 'package:dilivvafast/core/services/fare_calculator_service.dart';
import 'package:dilivvafast/core/infrastructure/notification/notification_service.dart';
import 'package:dilivvafast/core/constants/firestore_constants.dart';

// ==================== FIREBASE INSTANCE PROVIDERS ====================

final firestoreProvider = Provider<FirebaseFirestore>(
    (ref) => FirebaseFirestore.instance);

final firebaseAuthProvider = Provider<FirebaseAuth>(
    (ref) => FirebaseAuth.instance);

final firebaseStorageProvider = Provider<FirebaseStorage>(
    (ref) => FirebaseStorage.instance);

final firebaseFunctionsProvider = Provider<FirebaseFunctions>(
    (ref) => FirebaseFunctions.instance);

// ==================== REPOSITORY PROVIDERS ====================

final authRepositoryProvider = Provider<IAuthRepository>((ref) {
  return FirebaseAuthRepository(
    auth: ref.watch(firebaseAuthProvider),
    firestore: ref.watch(firestoreProvider),
  );
});

final userRepositoryProvider = Provider<IUserRepository>((ref) {
  return FirebaseUserRepository(
    firestore: ref.watch(firestoreProvider),
    storage: ref.watch(firebaseStorageProvider),
  );
});

final courierRepositoryProvider = Provider<ICourierRepository>((ref) {
  return FirebaseCourierRepository(
    firestore: ref.watch(firestoreProvider),
  );
});

final paymentRepositoryProvider = Provider<IPaymentRepository>((ref) {
  return FirebasePaymentRepository(
    firestore: ref.watch(firestoreProvider),
    functions: ref.watch(firebaseFunctionsProvider),
  );
});

final investorRepositoryProvider = Provider<IInvestorRepository>((ref) {
  return FirebaseInvestorRepository(
    firestore: ref.watch(firestoreProvider),
  );
});

// ==================== CORE SERVICE PROVIDERS ====================

final fareCalculatorProvider = Provider<FareCalculatorService>((ref) {
  return FareCalculatorService(firestore: ref.watch(firestoreProvider));
});

final notificationServiceProvider =
    Provider<NotificationService>((ref) => NotificationService(ref));

// ==================== AUTH STATE PROVIDERS ====================

/// Stream of Firebase Auth state
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

/// Current authenticated user ID
final currentUserIdProvider = Provider<String?>((ref) {
  return ref.watch(authStateProvider).value?.uid;
});

// ==================== USER PROVIDERS ====================

/// Stream current user profile
final currentUserProvider = StreamProvider<UserModel?>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return Stream.value(null);
  return ref.watch(userRepositoryProvider).watchUser(userId);
});

/// Current user role
final currentUserRoleProvider = Provider<UserRole?>((ref) {
  return ref.watch(currentUserProvider).value?.role;
});

/// Wallet balance stream
final walletBalanceProvider = StreamProvider<double>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return Stream.value(0.0);
  return ref.watch(userRepositoryProvider).watchWalletBalance(userId);
});

/// Full online-driver records. ADMIN SCREENS ONLY — customers cannot read the
/// `users` collection, so this stream errors for them by design.
final onlineDriversProvider = StreamProvider<List<UserModel>>((ref) {
  return ref.watch(userRepositoryProvider).watchOnlineDrivers();
});

/// Courier presence for customer-facing surfaces (availability note, map
/// pins). Reads the public `driver_locations` projection, which carries no
/// personal or financial data.
final onlineDriverPresenceProvider =
    StreamProvider<List<DriverPresence>>((ref) {
  return ref.watch(userRepositoryProvider).watchOnlineDriverPresence();
});

// ==================== COURIER ORDER PROVIDERS ====================

/// Active order for current customer
final activeOrderProvider = StreamProvider<CourierOrderModel?>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return Stream.value(null);
  return ref.watch(courierRepositoryProvider).watchActiveOrder(userId);
});

/// Customer's order history
final customerOrdersProvider = StreamProvider<List<CourierOrderModel>>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return Stream.value([]);
  return ref.watch(courierRepositoryProvider).watchCustomerOrders(userId);
});

/// Driver's order history
final driverOrdersProvider = StreamProvider<List<CourierOrderModel>>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return Stream.value([]);
  return ref.watch(courierRepositoryProvider).watchDriverOrders(userId);
});

/// Pending orders (for driver home)
final pendingOrdersProvider = StreamProvider<List<CourierOrderModel>>((ref) {
  return ref.watch(courierRepositoryProvider).watchPendingOrders();
});

/// All orders (admin)
final allOrdersProvider = StreamProvider<List<CourierOrderModel>>((ref) {
  return ref.watch(courierRepositoryProvider).watchAllOrders();
});

/// Watch a specific order
final orderStreamProvider =
    StreamProvider.family<CourierOrderModel?, String>((ref, orderId) {
  return ref.watch(courierRepositoryProvider).watchOrder(orderId);
});

// ==================== PAYMENT PROVIDERS ====================

/// Transaction history for current user
final transactionsProvider = StreamProvider<List<TransactionModel>>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return Stream.value([]);
  return ref.watch(paymentRepositoryProvider).watchTransactions(userId);
});

// ==================== INVESTOR PROVIDERS ====================

/// Current investor profile
final currentInvestorProvider = StreamProvider<InvestorModel?>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return Stream.value(null);
  return ref.watch(investorRepositoryProvider).watchInvestorProfile(userId);
});

/// Investor's bikes
final investorBikesProvider = StreamProvider<List<BikeModel>>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return Stream.value([]);
  return ref.watch(investorRepositoryProvider).watchInvestorBikes(userId);
});

/// Available bikes for funding
final availableBikesProvider = StreamProvider<List<BikeModel>>((ref) {
  return ref.watch(investorRepositoryProvider).watchAvailableBikes();
});

/// Investor HP agreements
final investorAgreementsProvider =
    StreamProvider<List<HPAgreementModel>>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return Stream.value([]);
  return ref
      .watch(investorRepositoryProvider)
      .watchInvestorAgreements(userId);
});

/// Investor earnings
final investorEarningsProvider =
    StreamProvider<List<InvestorEarningsModel>>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return Stream.value([]);
  return ref
      .watch(investorRepositoryProvider)
      .watchInvestorEarnings(userId);
});

/// Investor withdrawals
final investorWithdrawalsProvider =
    StreamProvider<List<InvestorWithdrawalModel>>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return Stream.value([]);
  return ref
      .watch(investorRepositoryProvider)
      .watchWithdrawals(userId);
});

// ==================== NOTIFICATION PROVIDERS ====================

/// Notifications for current user
final notificationsProvider =
    StreamProvider<List<NotificationModel>>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return Stream.value([]);
  return ref
      .watch(firestoreProvider)
      .collection(FirestoreConstants.notifications)
      .where(FirestoreConstants.fieldUserId, isEqualTo: userId)
      .orderBy(FirestoreConstants.fieldCreatedAt, descending: true)
      .limit(50)
      .snapshots()
      .map((snap) =>
          snap.docs.map((d) => NotificationModel.fromFirestore(d)).toList());
});

/// Unread notification count
final unreadNotificationCountProvider = Provider<int>((ref) {
  final notifications = ref.watch(notificationsProvider).value ?? [];
  return notifications.where((n) => !n.isRead).length;
});

// ==================== DRIVER STATUS PROVIDERS ====================

/// Driver online/offline toggle notifier
class DriverStatusNotifier extends Notifier<bool> {
  /// Seeded from the profile so a driver who was online before the app was
  /// reopened is not shown as offline while Firestore still has them live.
  @override
  bool build() => ref.watch(currentUserProvider).value?.isOnline ?? false;

  Future<void> toggle() async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;

    final previous = state;
    final newStatus = !previous;
    state = newStatus;

    final result = await ref
        .read(userRepositoryProvider)
        .updateOnlineStatus(userId, newStatus, newStatus);

    // Roll back so the switch cannot claim a state the backend rejected.
    result.fold((_) => state = previous, (_) {});
  }

  void set(bool value) => state = value;
}

final driverOnlineProvider =
    NotifierProvider<DriverStatusNotifier, bool>(DriverStatusNotifier.new);

// ==================== PHASE 4: LOCATION & FCM PROVIDERS ====================

/// Location tracking service (singleton)
final locationTrackingServiceProvider = Provider<LocationTrackingService>((ref) {
  final service = LocationTrackingService(
    firestore: ref.watch(firestoreProvider),
  );
  ref.onDispose(() => service.dispose());
  return service;
});

/// FCM notification service
final fcmServiceProvider = Provider<FCMService>((ref) {
  return FCMService(
    firestore: ref.watch(firestoreProvider),
  );
});

/// Stream one courier's live position, for the tracking map.
///
/// Reads `driver_locations`, not `users` — a customer tracking their delivery
/// needs coordinates, not the courier's email, phone and wallet balance.
final driverLocationProvider =
    StreamProvider.family<GeoPoint?, String>((ref, driverId) {
  return ref
      .watch(firestoreProvider)
      .collection(FirestoreConstants.driverLocations)
      .doc(driverId)
      .snapshots()
      .map((snap) => snap.data()?['location'] as GeoPoint?);
});
