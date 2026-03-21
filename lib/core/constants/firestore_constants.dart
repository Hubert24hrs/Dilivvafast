/// Firestore collection names and field constants.
abstract class FirestoreConstants {
  // Collection names
  static const String users = 'users';
  static const String couriers = 'couriers';
  static const String rides = 'rides';
  static const String transactions = 'transactions';
  static const String driverApplications = 'driver_applications';
  static const String ratings = 'ratings';
  static const String promos = 'promos';
  static const String referrals = 'referrals';
  static const String favoriteDrivers = 'favorite_drivers';
  static const String savedDestinations = 'saved_destinations';
  static const String investors = 'investors';
  static const String bikes = 'bikes';
  static const String hpAgreements = 'hp_agreements';
  static const String investorEarnings = 'investor_earnings';
  static const String investorWithdrawals = 'investor_withdrawals';
  static const String notifications = 'notifications';
  static const String supportTickets = 'support_tickets';
  static const String appConfig = 'app_config';
  static const String zones = 'zones';

  // Subcollection names
  static const String messages = 'messages';

  // Common fields
  static const String fieldCreatedAt = 'createdAt';
  static const String fieldUpdatedAt = 'updatedAt';
  static const String fieldUserId = 'userId';
  static const String fieldStatus = 'status';
  static const String fieldDriverId = 'driverId';
  static const String fieldIsOnline = 'isOnline';
  static const String fieldIsAvailable = 'isAvailable';
  static const String fieldRole = 'role';
}
