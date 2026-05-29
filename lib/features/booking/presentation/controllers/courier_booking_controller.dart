import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dilivvafast/core/providers/providers.dart';
import 'package:dilivvafast/core/services/fare_calculator_service.dart';
import 'package:dilivvafast/core/services/location_helper.dart';
import 'package:dilivvafast/features/courier/domain/entities/courier_order_model.dart';

/// Vehicle type for courier delivery.
enum VehicleType { car, motorcycle }

/// State for the map-based courier booking screen.
class CourierBookingState {
  const CourierBookingState({
    this.vehicleType = VehicleType.motorcycle,
    this.pickupAddress = '',
    this.pickupLat = 0,
    this.pickupLng = 0,
    this.dropoffAddress = '',
    this.dropoffLat = 0,
    this.dropoffLng = 0,
    this.packageDescription = '',
    this.packageCategory = PackageCategory.other,
    this.packageWeight = 0.0,
    this.recipientName = '',
    this.recipientPhone = '',
    this.notes = '',
    this.proposedPrice = 0.0,
    this.paymentMethod = PaymentMethod.wallet,
    this.fareBreakdown,
    this.isLoadingLocation = false,
    this.isSubmitting = false,
    this.isCalculatingFare = false,
    this.locationStatus = LocationStatus.granted,
    this.error,
    this.createdOrderId,
    this.packageDetailsExpanded = false,
  });

  final VehicleType vehicleType;
  final String pickupAddress;
  final double pickupLat;
  final double pickupLng;
  final String dropoffAddress;
  final double dropoffLat;
  final double dropoffLng;
  final String packageDescription;
  final PackageCategory packageCategory;
  final double packageWeight;
  final String recipientName;
  final String recipientPhone;
  final String notes;
  final double proposedPrice;
  final PaymentMethod paymentMethod;
  final FareBreakdown? fareBreakdown;
  final bool isLoadingLocation;
  final bool isSubmitting;
  final bool isCalculatingFare;
  final LocationStatus locationStatus;
  final String? error;
  final String? createdOrderId;
  final bool packageDetailsExpanded;

  CourierBookingState copyWith({
    VehicleType? vehicleType,
    String? pickupAddress,
    double? pickupLat,
    double? pickupLng,
    String? dropoffAddress,
    double? dropoffLat,
    double? dropoffLng,
    String? packageDescription,
    PackageCategory? packageCategory,
    double? packageWeight,
    String? recipientName,
    String? recipientPhone,
    String? notes,
    double? proposedPrice,
    PaymentMethod? paymentMethod,
    FareBreakdown? fareBreakdown,
    bool? isLoadingLocation,
    bool? isSubmitting,
    bool? isCalculatingFare,
    LocationStatus? locationStatus,
    String? error,
    String? createdOrderId,
    bool? packageDetailsExpanded,
  }) {
    return CourierBookingState(
      vehicleType: vehicleType ?? this.vehicleType,
      pickupAddress: pickupAddress ?? this.pickupAddress,
      pickupLat: pickupLat ?? this.pickupLat,
      pickupLng: pickupLng ?? this.pickupLng,
      dropoffAddress: dropoffAddress ?? this.dropoffAddress,
      dropoffLat: dropoffLat ?? this.dropoffLat,
      dropoffLng: dropoffLng ?? this.dropoffLng,
      packageDescription: packageDescription ?? this.packageDescription,
      packageCategory: packageCategory ?? this.packageCategory,
      packageWeight: packageWeight ?? this.packageWeight,
      recipientName: recipientName ?? this.recipientName,
      recipientPhone: recipientPhone ?? this.recipientPhone,
      notes: notes ?? this.notes,
      proposedPrice: proposedPrice ?? this.proposedPrice,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      fareBreakdown: fareBreakdown ?? this.fareBreakdown,
      isLoadingLocation: isLoadingLocation ?? this.isLoadingLocation,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isCalculatingFare: isCalculatingFare ?? this.isCalculatingFare,
      locationStatus: locationStatus ?? this.locationStatus,
      error: error,
      createdOrderId: createdOrderId,
      packageDetailsExpanded:
          packageDetailsExpanded ?? this.packageDetailsExpanded,
    );
  }

  /// Haversine distance in km between pickup and dropoff
  double get distanceKm {
    if (pickupLat == 0 || dropoffLat == 0) return 0;
    const earthRadius = 6371.0;
    final dLat = _degToRad(dropoffLat - pickupLat);
    final dLng = _degToRad(dropoffLng - pickupLng);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degToRad(pickupLat)) *
            cos(_degToRad(dropoffLat)) *
            sin(dLng / 2) *
            sin(dLng / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  double _degToRad(double deg) => deg * pi / 180;

  bool get hasPickup => pickupAddress.isNotEmpty && pickupLat != 0;
  bool get hasDropoff => dropoffAddress.isNotEmpty && dropoffLat != 0;
  bool get hasPackageDetails =>
      packageDescription.isNotEmpty &&
      recipientName.isNotEmpty &&
      recipientPhone.length >= 10;

  bool get canFindCourier => hasPickup && hasDropoff;

  String get pickupDisplayText {
    if (isLoadingLocation) return 'Getting your location...';
    if (pickupAddress.isNotEmpty) return pickupAddress;
    if (locationStatus == LocationStatus.servicesDisabled) {
      return 'Location services disabled';
    }
    if (locationStatus == LocationStatus.permissionDenied ||
        locationStatus == LocationStatus.permissionDeniedForever) {
      return 'Location permission denied';
    }
    return 'Location unavailable';
  }
}

/// Controller for the courier booking screen.
class CourierBookingController extends Notifier<CourierBookingState> {
  @override
  CourierBookingState build() => const CourierBookingState();

  /// Initialize: get current location and reverse-geocode it.
  Future<void> initializeLocation() async {
    state = state.copyWith(isLoadingLocation: true, error: null);

    final locationHelper = ref.read(locationHelperProvider);

    // Check location status first
    final status = await locationHelper.checkLocationStatus();
    if (status != LocationStatus.granted) {
      // Try requesting permission
      final granted = await locationHelper.requestPermission();
      if (!granted) {
        state = state.copyWith(
          isLoadingLocation: false,
          locationStatus: status,
        );
        return;
      }
    }

    // Get current position
    final position = await locationHelper.getCurrentPosition();
    if (position != null) {
      final address = await locationHelper.reverseGeocode(
        position.latitude,
        position.longitude,
      );
      state = state.copyWith(
        pickupAddress: address,
        pickupLat: position.latitude,
        pickupLng: position.longitude,
        isLoadingLocation: false,
        locationStatus: LocationStatus.granted,
      );
    } else {
      // Fallback to Lagos
      state = state.copyWith(
        isLoadingLocation: false,
        locationStatus: status,
      );
    }
  }

  void setVehicleType(VehicleType type) {
    state = state.copyWith(vehicleType: type);
  }

  void setPickup(String address, double lat, double lng) {
    state = state.copyWith(
      pickupAddress: address,
      pickupLat: lat,
      pickupLng: lng,
      locationStatus: LocationStatus.granted,
    );
  }

  void setDropoff(String address, double lat, double lng) {
    state = state.copyWith(
      dropoffAddress: address,
      dropoffLat: lat,
      dropoffLng: lng,
    );
  }

  void setPackageCategory(PackageCategory cat) =>
      state = state.copyWith(packageCategory: cat);

  void setPackageWeight(double w) =>
      state = state.copyWith(packageWeight: w);

  void setPackageDescription(String d) =>
      state = state.copyWith(packageDescription: d);

  void setRecipientName(String n) =>
      state = state.copyWith(recipientName: n);

  void setRecipientPhone(String p) =>
      state = state.copyWith(recipientPhone: p);

  void setNotes(String n) => state = state.copyWith(notes: n);

  void setProposedPrice(double p) =>
      state = state.copyWith(proposedPrice: p);

  void setPaymentMethod(PaymentMethod m) =>
      state = state.copyWith(paymentMethod: m);

  void togglePackageDetails() => state = state.copyWith(
      packageDetailsExpanded: !state.packageDetailsExpanded);

  /// Calculate the fare based on current state.
  Future<void> calculateFare() async {
    if (!state.hasPickup || !state.hasDropoff) return;

    state = state.copyWith(isCalculatingFare: true, error: null);
    try {
      final fareCalc = ref.read(fareCalculatorProvider);
      final breakdown = await fareCalc.calculateFare(
        distanceKm: state.distanceKm,
        packageWeightKg: state.packageWeight,
        pickupLat: state.pickupLat,
        pickupLng: state.pickupLng,
      );
      state = state.copyWith(
        fareBreakdown: breakdown,
        isCalculatingFare: false,
      );
    } catch (e) {
      state = state.copyWith(
        isCalculatingFare: false,
        error: 'Failed to calculate fare: $e',
      );
    }
  }

  /// Validate inputs and submit the order.
  /// Returns the orderId on success, null on failure.
  Future<String?> submitOrder() async {
    if (state.isSubmitting) return null;

    // Validate
    if (!state.hasPickup) {
      state = state.copyWith(error: 'Please set a pickup location');
      return null;
    }
    if (!state.hasDropoff) {
      state = state.copyWith(error: 'Please set a destination');
      return null;
    }

    state = state.copyWith(isSubmitting: true, error: null);

    try {
      final userId = ref.read(currentUserIdProvider);
      if (userId == null) {
        state = state.copyWith(
            isSubmitting: false, error: 'Not authenticated');
        return null;
      }

      // Calculate fare if not done yet
      if (state.fareBreakdown == null) {
        await calculateFare();
      }

      final courierRepo = ref.read(courierRepositoryProvider);
      final now = DateTime.now();
      final trackingCode =
          'DLV${now.millisecondsSinceEpoch.toString().substring(5)}';

      final totalFare = state.proposedPrice > 0
          ? state.proposedPrice
          : (state.fareBreakdown?.totalFare ?? 500.0);

      final order = CourierOrderModel(
        id: '',
        userId: userId,
        status: OrderStatus.pending,
        pickupAddress: state.pickupAddress,
        pickupGeoPoint: GeoPoint(state.pickupLat, state.pickupLng),
        dropoffAddress: state.dropoffAddress,
        dropoffGeoPoint: GeoPoint(state.dropoffLat, state.dropoffLng),
        packageDescription: state.packageDescription.isNotEmpty
            ? state.packageDescription
            : 'Package',
        packageWeight: state.packageWeight,
        packageCategory: state.packageCategory,
        recipientName: state.recipientName.isNotEmpty
            ? state.recipientName
            : 'Recipient',
        recipientPhone: state.recipientPhone.isNotEmpty
            ? state.recipientPhone
            : '0000000000',
        estimatedDistanceKm: state.distanceKm,
        estimatedDurationMin: (state.distanceKm * 4).round(),
        baseFare: state.fareBreakdown?.baseFare ?? 500.0,
        surgeMultiplier: state.fareBreakdown?.surgeMultiplier ?? 1.0,
        totalFare: totalFare,
        paymentMethod: state.paymentMethod,
        trackingCode: trackingCode,
        notes: state.notes.isNotEmpty
            ? '${state.vehicleType.name} | ${state.notes}'
            : state.vehicleType.name,
        driverEarnings: totalFare * 0.80,
        platformCommission: totalFare * 0.20,
        createdAt: now,
        updatedAt: now,
      );

      final result = await courierRepo.createOrder(order);
      return result.fold(
        (failure) {
          state = state.copyWith(
            isSubmitting: false,
            error: failure.message,
          );
          return null;
        },
        (createdOrder) {
          state = state.copyWith(
            isSubmitting: false,
            createdOrderId: createdOrder.id,
          );
          return createdOrder.id;
        },
      );
    } catch (e) {
      debugPrint('CourierBookingController.submitOrder error: $e');
      state = state.copyWith(
        isSubmitting: false,
        error: 'Failed to create order: $e',
      );
      return null;
    }
  }

  void clearError() => state = state.copyWith(error: null);

  void reset() => state = const CourierBookingState();
}

final courierBookingControllerProvider =
    NotifierProvider<CourierBookingController, CourierBookingState>(
        CourierBookingController.new);
