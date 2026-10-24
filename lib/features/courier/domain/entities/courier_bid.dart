import 'package:cloud_firestore/cloud_firestore.dart';

/// Lifecycle of a driver's offer on a delivery request.
enum BidStatus {
  /// Waiting for the customer.
  open,

  /// The customer picked this offer; the driver is now assigned.
  accepted,

  /// The customer turned it down, or picked someone else.
  declined,

  /// The driver withdrew it before the customer answered.
  withdrawn;

  static BidStatus fromWire(String? value) => BidStatus.values.firstWhere(
    (s) => s.name == value,
    orElse: () => BidStatus.open,
  );
}

/// One driver's offer on one delivery request — the inDrive-style counterpart
/// to the customer's own offer.
///
/// Stored at `couriers/{orderId}/bids/{driverId}`, so a driver holds at most
/// one live offer per request and can revise it in place.
///
/// Only [amount] and [etaMinutes] come from the driver's device. Everything
/// describing the driver — name, photo, rating, vehicle — is filled in by the
/// `onBidWritten` Cloud Function from the driver's own record, and
/// firestore.rules refuses those fields from a client. A customer choosing
/// between offers can therefore trust that the rating and plate they see are
/// real, not whatever a driver typed.
class CourierBid {
  const CourierBid({
    required this.driverId,
    required this.amount,
    required this.status,
    this.etaMinutes,
    this.driverName,
    this.driverPhotoUrl,
    this.driverRating,
    this.driverTrips,
    this.vehicleLabel,
    this.vehiclePlate,
    this.createdAt,
  });

  final String driverId;
  final double amount;
  final BidStatus status;
  final int? etaMinutes;
  final String? driverName;
  final String? driverPhotoUrl;
  final double? driverRating;
  final int? driverTrips;
  final String? vehicleLabel;
  final String? vehiclePlate;
  final DateTime? createdAt;

  bool get isOpen => status == BidStatus.open;

  /// Until the server has filled in the driver's details the offer cannot be
  /// shown meaningfully, so the customer list skips it for that brief moment.
  bool get isEnriched => driverName != null;

  factory CourierBid.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? const {};
    return CourierBid(
      driverId: doc.id,
      amount: (data['amount'] as num?)?.toDouble() ?? 0,
      status: BidStatus.fromWire(data['status'] as String?),
      etaMinutes: (data['etaMinutes'] as num?)?.toInt(),
      driverName: data['driverName'] as String?,
      driverPhotoUrl: data['driverPhotoUrl'] as String?,
      driverRating: (data['driverRating'] as num?)?.toDouble(),
      driverTrips: (data['driverTrips'] as num?)?.toInt(),
      vehicleLabel: data['vehicleLabel'] as String?,
      vehiclePlate: data['vehiclePlate'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}

/// The price band a negotiation is allowed to move within.
///
/// Mirrors the bounds the backend enforces (`onCourierCreated`, `raiseOffer`,
/// and the bid rules). Kept on the client only to give immediate feedback —
/// the server is the authority, and a value outside the band is clamped or
/// rejected there regardless of what this says.
class NegotiationBounds {
  const NegotiationBounds({required this.recommended});

  final double recommended;

  /// Absolute minimum fare for any delivery.
  static const double minimumFare = 500;

  /// A customer may offer down to 70% of the recommended fare...
  static const double floorRatio = 0.7;

  /// ...and the price can never exceed three times it.
  static const double ceilingRatio = 3.0;

  double get floor {
    final ratioFloor = (recommended * floorRatio / 50).ceil() * 50.0;
    return ratioFloor < minimumFare ? minimumFare : ratioFloor;
  }

  double get ceiling {
    final c = recommended * ceilingRatio;
    return c < floor ? floor : c;
  }

  double clamp(double value) => value.clamp(floor, ceiling).toDouble();
}
