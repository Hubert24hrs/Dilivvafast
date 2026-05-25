/// Tracks a rider's payment obligation cycle.
/// After every 3 completed rides the rider owes 10% of each fare to the platform.
class RiderPaymentStatus {
  final String riderId;

  /// How many rides completed since last payment (resets to 0 after payment).
  final int completedRidesCount;

  /// Accumulated 10%-platform-fee debt in Naira (kobo-accurate).
  final double accumulatedDebt;

  /// True when completedRidesCount >= 3 and payment hasn't been made yet.
  final bool isBlocked;

  /// ISO-8601 timestamp of last successful payment.
  final DateTime? lastPaymentAt;

  /// Fares from the last 3 rides (for receipt display).
  final List<double> lastRideFares;

  const RiderPaymentStatus({
    required this.riderId,
    required this.completedRidesCount,
    required this.accumulatedDebt,
    required this.isBlocked,
    this.lastPaymentAt,
    this.lastRideFares = const [],
  });

  factory RiderPaymentStatus.fromMap(Map<String, dynamic> map) {
    return RiderPaymentStatus(
      riderId: map['riderId'] as String? ?? '',
      completedRidesCount: (map['completedRidesCount'] as num?)?.toInt() ?? 0,
      accumulatedDebt: (map['accumulatedDebt'] as num?)?.toDouble() ?? 0.0,
      isBlocked: map['isBlocked'] as bool? ?? false,
      lastPaymentAt: map['lastPaymentAt'] != null
          ? DateTime.tryParse(map['lastPaymentAt'] as String)
          : null,
      lastRideFares: (map['lastRideFares'] as List<dynamic>?)
              ?.map((e) => (e as num).toDouble())
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toMap() => {
        'riderId': riderId,
        'completedRidesCount': completedRidesCount,
        'accumulatedDebt': accumulatedDebt,
        'isBlocked': isBlocked,
        'lastPaymentAt': lastPaymentAt?.toIso8601String(),
        'lastRideFares': lastRideFares,
      };

  RiderPaymentStatus copyWith({
    int? completedRidesCount,
    double? accumulatedDebt,
    bool? isBlocked,
    DateTime? lastPaymentAt,
    List<double>? lastRideFares,
  }) {
    return RiderPaymentStatus(
      riderId: riderId,
      completedRidesCount: completedRidesCount ?? this.completedRidesCount,
      accumulatedDebt: accumulatedDebt ?? this.accumulatedDebt,
      isBlocked: isBlocked ?? this.isBlocked,
      lastPaymentAt: lastPaymentAt ?? this.lastPaymentAt,
      lastRideFares: lastRideFares ?? this.lastRideFares,
    );
  }

  /// Friendly display string e.g. "You owe ₦4,850 for 3 rides"
  String get debtSummary =>
      'You owe ₦${accumulatedDebt.toStringAsFixed(0)} for $completedRidesCount ride${completedRidesCount == 1 ? '' : 's'}';
}
