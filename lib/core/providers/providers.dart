

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dilivvafast/core/models/rider_payment_status.dart';
import 'package:dilivvafast/core/services/rider_payment_service.dart';

import 'package:dilivvafast/core/models/courier_model.dart';
import 'package:dilivvafast/core/models/ride_model.dart';
import 'package:dilivvafast/core/models/bike_model.dart';
import 'package:dilivvafast/core/models/investor_model.dart';
import 'package:dilivvafast/core/models/hp_agreement_model.dart';
import 'package:dilivvafast/core/models/investor_earnings_model.dart';
import 'package:dilivvafast/core/services/admin_service.dart';
import 'package:dilivvafast/core/services/auth_service.dart';
import 'package:dilivvafast/core/services/database_service.dart';
import 'package:dilivvafast/core/services/location_service.dart';
import 'package:dilivvafast/core/services/notification_service.dart';
import 'package:dilivvafast/core/services/paystack_service.dart';
import 'package:dilivvafast/core/services/saved_destinations_service.dart';
import 'package:dilivvafast/core/services/earnings_service.dart';
import 'package:dilivvafast/core/services/rating_service.dart';
import 'package:dilivvafast/core/services/favorite_drivers_service.dart';
import 'package:dilivvafast/core/services/email_service.dart';
import 'package:dilivvafast/core/services/investor_service.dart';
import 'package:dilivvafast/core/services/revenue_split_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dilivvafast/core/services/ride_service.dart';
import 'package:dilivvafast/core/services/storage_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ... other providers

final rideServiceProvider = Provider<RideService>((ref) {
  return RideService();
});

final ridesStreamProvider = StreamProvider<List<RideModel>>((ref) {
  return ref.watch(rideServiceProvider).getAvailableRides();
});


// Services
final authServiceProvider = Provider<AuthService>((ref) => AuthService());
final databaseServiceProvider = Provider<DatabaseService>((ref) => DatabaseService());
final locationServiceProvider = Provider<LocationService>((ref) => LocationService());
final storageServiceProvider = Provider<StorageService>((ref) => StorageService());
final savedDestinationsServiceProvider = Provider<SavedDestinationsService>((ref) => SavedDestinationsService());
final earningsServiceProvider = Provider<EarningsService>((ref) => EarningsService());
final ratingServiceProvider = Provider<RatingService>((ref) => RatingService());
final favoriteDriversServiceProvider = Provider<FavoriteDriversService>((ref) => FavoriteDriversService());
final emailServiceProvider = Provider<EmailService>((ref) => EmailService());
final notificationServiceProvider = Provider<NotificationService>((ref) => NotificationService(ref));

// Auth State
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

// Current User ID
final currentUserIdProvider = Provider<String?>((ref) {
  return ref.watch(authStateProvider).value?.uid;
});

// Active Requests Streams
final activeRidesProvider = StreamProvider<List<RideModel>>((ref) {
  return ref.watch(databaseServiceProvider).getActiveRides();
});

final activeCouriersProvider = StreamProvider<List<CourierModel>>((ref) {
  return ref.watch(databaseServiceProvider).getActiveCouriers();
});

// Driver Online Status
// Driver Online Status
class DriverStatusNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void set(bool value) => state = value;
  void toggle() => state = !state;
}

final driverOnlineProvider = NotifierProvider<DriverStatusNotifier, bool>(DriverStatusNotifier.new);

// Current User Role (for route protection)
final currentUserRoleProvider = StreamProvider<String?>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return Stream.value(null);
  
  return ref.watch(databaseServiceProvider).getUserStream(userId).map((user) => user?.role);
});

// ==================== INVESTOR PROVIDERS ====================

// Investor Service
final investorServiceProvider = Provider<InvestorService>((ref) => InvestorService(ref));
final revenueSplitServiceProvider = Provider<RevenueSplitService>((ref) => RevenueSplitService(ref));

// Current Investor Profile
final currentInvestorProvider = StreamProvider<InvestorModel?>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return Stream.value(null);
  return ref.watch(investorServiceProvider).streamInvestorProfile(userId);
});

// Investor's Bikes Portfolio
final investorBikesProvider = StreamProvider<List<BikeModel>>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return Stream.value([]);
  return ref.watch(investorServiceProvider).getInvestorBikes(userId);
});

// Investor's HP Agreements
final investorAgreementsProvider = StreamProvider<List<HPAgreementModel>>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return Stream.value([]);
  return ref.watch(investorServiceProvider).getInvestorAgreements(userId);
});

// Investor's Earnings
final investorEarningsProvider = StreamProvider<List<InvestorEarningsModel>>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return Stream.value([]);
  return ref.watch(investorServiceProvider).getInvestorEarnings(userId);
});

// Available Bike Campaigns (for funding)
final availableBikeCampaignsProvider = StreamProvider<List<BikeModel>>((ref) {
  return ref.watch(investorServiceProvider).getAvailableBikeCampaigns();
});

// Investor's Withdrawal History
final investorWithdrawalsProvider = StreamProvider<List<InvestorWithdrawalModel>>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return Stream.value([]);
  return ref.watch(investorServiceProvider).getWithdrawalHistory(userId);
});

// Check if current user is an investor
final isInvestorProvider = FutureProvider<bool>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return false;
  return ref.watch(investorServiceProvider).isInvestor(userId);
});

// Admin Service Provider
final adminServiceProvider = Provider<AdminService>((ref) {
  return AdminService(FirebaseFirestore.instance);
});

// Paystack Service Provider
final paystackServiceProvider = Provider<PaystackService>((ref) {
  return PaystackService();
});


// ==================== RIDER PAYMENT PROVIDERS ====================

final riderPaymentServiceProvider = Provider<RiderPaymentService>((ref) {
  return RiderPaymentService();
});

/// Stream of the current rider's payment status.
final riderPaymentStatusProvider =
    StreamProvider.autoDispose<RiderPaymentStatus>((ref) {
  final uid = ref.watch(currentUserIdProvider);
  if (uid == null) {
    return Stream.value(RiderPaymentStatus(
      riderId: '',
      completedRidesCount: 0,
      accumulatedDebt: 0,
      isBlocked: false,
    ));
  }
  return ref.watch(riderPaymentServiceProvider).statusStream(uid);
});

/// Convenience: is the current rider blocked?
final riderIsBlockedProvider = Provider.autoDispose<bool>((ref) {
  return ref.watch(riderPaymentStatusProvider).maybeWhen(
        data: (s) => s.isBlocked,
        orElse: () => false,
      );
});

// --- Constants ---
