import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fast_delivery/core/providers/providers.dart';
import 'package:fast_delivery/core/services/fare_calculator_service.dart';
import 'package:fast_delivery/features/courier/domain/entities/courier_order_model.dart';

/// State for the multi-step booking wizard.
class BookingState {
  const BookingState({
    this.step = 0,
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
    this.promoCode = '',
    this.paymentMethod = PaymentMethod.wallet,
    this.fareBreakdown,
    this.isCalculatingFare = false,
    this.isSubmitting = false,
    this.error,
    this.createdOrderId,
  });

  final int step;
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
  final String promoCode;
  final PaymentMethod paymentMethod;
  final FareBreakdown? fareBreakdown;
  final bool isCalculatingFare;
  final bool isSubmitting;
  final String? error;
  final String? createdOrderId;

  BookingState copyWith({
    int? step,
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
    String? promoCode,
    PaymentMethod? paymentMethod,
    FareBreakdown? fareBreakdown,
    bool? isCalculatingFare,
    bool? isSubmitting,
    String? error,
    String? createdOrderId,
  }) {
    return BookingState(
      step: step ?? this.step,
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
      promoCode: promoCode ?? this.promoCode,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      fareBreakdown: fareBreakdown ?? this.fareBreakdown,
      isCalculatingFare: isCalculatingFare ?? this.isCalculatingFare,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: error,
      createdOrderId: createdOrderId,
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

  bool get canProceedFromPickup => pickupAddress.isNotEmpty;
  bool get canProceedFromDropoff => dropoffAddress.isNotEmpty;
  bool get canProceedFromPackage =>
      packageDescription.isNotEmpty &&
      recipientName.isNotEmpty &&
      recipientPhone.length >= 10;
}

/// Manages the booking flow state using Riverpod 3.x Notifier.
class BookingController extends Notifier<BookingState> {
  @override
  BookingState build() => const BookingState();

  void setPickup(String address, double lat, double lng) {
    state = state.copyWith(
      pickupAddress: address,
      pickupLat: lat,
      pickupLng: lng,
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

  void setPromoCode(String c) => state = state.copyWith(promoCode: c);

  void setPaymentMethod(PaymentMethod m) =>
      state = state.copyWith(paymentMethod: m);

  void nextStep() {
    if (state.step < 3) {
      state = state.copyWith(step: state.step + 1);
      // Auto-calculate fare when reaching fare step
      if (state.step == 3) {
        calculateFare();
      }
    }
  }

  void previousStep() {
    if (state.step > 0) {
      state = state.copyWith(step: state.step - 1);
    }
  }

  void goToStep(int s) => state = state.copyWith(step: s);

  /// Calculate fare using FareCalculatorService
  Future<void> calculateFare() async {
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

  /// Submit the order to Firestore
  Future<void> submitOrder() async {
    if (state.isSubmitting) return;
    state = state.copyWith(isSubmitting: true, error: null);

    try {
      final userId = ref.read(currentUserIdProvider);
      if (userId == null) {
        state = state.copyWith(
            isSubmitting: false, error: 'Not authenticated');
        return;
      }

      final courierRepo = ref.read(courierRepositoryProvider);
      final now = DateTime.now();
      final trackingCode =
          'DLV${now.millisecondsSinceEpoch.toString().substring(5)}';

      final order = CourierOrderModel(
        id: '', // Will be set by Firestore
        userId: userId,
        status: OrderStatus.pending,
        pickupAddress: state.pickupAddress,
        pickupGeoPoint:
            GeoPoint(state.pickupLat, state.pickupLng),
        dropoffAddress: state.dropoffAddress,
        dropoffGeoPoint:
            GeoPoint(state.dropoffLat, state.dropoffLng),
        packageDescription: state.packageDescription,
        packageWeight: state.packageWeight,
        packageCategory: state.packageCategory,
        recipientName: state.recipientName,
        recipientPhone: state.recipientPhone,
        estimatedDistanceKm: state.distanceKm,
        estimatedDurationMin: (state.distanceKm * 4).round(), // ~15 km/h avg
        baseFare: state.fareBreakdown?.baseFare ?? 0,
        surgeMultiplier: state.fareBreakdown?.surgeMultiplier ?? 1.0,
        totalFare: state.fareBreakdown?.totalFare ?? 0,
        paymentMethod: state.paymentMethod,
        promoCode:
            state.promoCode.isNotEmpty ? state.promoCode : null,
        discountAmount: state.fareBreakdown?.promoDiscount ?? 0,
        trackingCode: trackingCode,
        notes: state.notes.isNotEmpty ? state.notes : null,
        driverEarnings: (state.fareBreakdown?.totalFare ?? 0) * 0.80,
        platformCommission: (state.fareBreakdown?.totalFare ?? 0) * 0.20,
        createdAt: now,
        updatedAt: now,
      );

      final result = await courierRepo.createOrder(order);
      result.fold(
        (failure) => state = state.copyWith(
          isSubmitting: false,
          error: failure.message,
        ),
        (createdOrder) => state = state.copyWith(
          isSubmitting: false,
          createdOrderId: createdOrder.id,
        ),
      );
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        error: 'Failed to create order: $e',
      );
    }
  }

  void reset() => state = const BookingState();
}

final bookingControllerProvider =
    NotifierProvider<BookingController, BookingState>(
        BookingController.new);
