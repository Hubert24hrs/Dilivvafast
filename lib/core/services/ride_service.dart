import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fast_delivery/core/models/ride_model.dart';
import 'package:fast_delivery/core/services/notification_service.dart';
import 'package:flutter/foundation.dart';

class RideService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection Reference
  CollectionReference<Map<String, dynamic>> get _ridesCollection =>
      _firestore.collection('rides');

  // Create a new ride request
  Future<void> createRide(RideModel ride) async {
    debugPrint('RideService.createRide: Creating ride with id=${ride.id}');
    try {
      await _ridesCollection.doc(ride.id).set(ride.toMap());
      debugPrint('RideService.createRide: SUCCESS - ride created');
    } catch (e) {
      debugPrint('RideService.createRide: ERROR - $e');
      rethrow;
    }
  }

  // Stream of available rides (status == 'pending')
  Stream<List<RideModel>> getAvailableRides() {
    return _ridesCollection
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return RideModel.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  // Accept a ride (convenience method)
  Future<void> acceptRide(String rideId, String driverId, String driverName) async {
    await updateRideStatus(
      rideId,
      'accepted',
      driverId: driverId,
      driverName: driverName,
    );
  }

  // Update ride status and assign driver
  Future<void> updateRideStatus(
    String rideId, 
    String status, {
    String? driverId,
    String? driverName,
    String? driverPhone,
    String? driverPhoto,
    String? carModel,
    String? plateNumber,
    GeoPoint? driverLocation,
  }) async {
    debugPrint('RideService: Updating ride $rideId to status $status');
    final Map<String, dynamic> data = {'status': status};
    
    if (driverId != null) data['driverId'] = driverId;
    if (driverName != null) data['driverName'] = driverName;
    if (driverPhone != null) data['driverPhone'] = driverPhone;
    if (driverPhoto != null) data['driverPhoto'] = driverPhoto;
    if (carModel != null) data['carModel'] = carModel;
    if (plateNumber != null) data['plateNumber'] = plateNumber;
    if (driverLocation != null) data['driverLocation'] = driverLocation;

    // Auto-set timestamp based on status
    final now = Timestamp.now();
    switch (status) {
      case 'accepted':
        data['acceptedAt'] = now;
        break;
      case 'arrived':
        data['arrivedAt'] = now;
        break;
      case 'in_progress':
        data['tripStartedAt'] = now;
        break;
      case 'completed':
        data['completedAt'] = now;
        break;
    }

    await _ridesCollection.doc(rideId).update(data);
    debugPrint('RideService: Successfully updated ride $rideId to $status');
  }

  // Stream a specific ride by ID (for tracking)
  Stream<RideModel?> streamRide(String rideId) {
    debugPrint('RideService.streamRide: Starting stream for rideId=$rideId');
    return _ridesCollection.doc(rideId).snapshots().map((doc) {
      debugPrint('RideService.streamRide: doc.exists=${doc.exists}, doc.id=${doc.id}');
      if (!doc.exists) {
        debugPrint('RideService.streamRide: Document does not exist!');
        return null; // Return null instead of throwing exception
      }
      final ride = RideModel.fromMap(doc.data()!, doc.id);
      debugPrint('RideService.streamRide: Ride status=${ride.status}');
      return ride;
    });
  }

  // Get active ride for user
  Future<RideModel?> getActiveRideForUser(String userId) async {
    try {
      final snapshot = await _ridesCollection
          .where('userId', isEqualTo: userId)
          .where('status', whereIn: ['pending', 'accepted', 'arrived', 'in_progress'])
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return RideModel.fromMap(snapshot.docs.first.data(), snapshot.docs.first.id);
      }
    } catch (e) {
      debugPrint('Error getting active ride: $e');
    }
    return null;
  }

  // Cancel ALL active rides for a user (cleanup utility)
  Future<int> cancelAllActiveRidesForUser(String userId) async {
    int cancelledCount = 0;
    try {
      final snapshot = await _ridesCollection
          .where('userId', isEqualTo: userId)
          .where('status', whereIn: ['pending', 'accepted', 'arrived', 'in_progress'])
          .get();

      for (final doc in snapshot.docs) {
        await doc.reference.update({'status': 'cancelled'});
        cancelledCount++;
        debugPrint('RideService: Cancelled ride ${doc.id}');
      }
    } catch (e) {
      debugPrint('Error cancelling all rides: $e');
    }
    return cancelledCount;
  }


  // Get active ride for driver
  Future<RideModel?> getActiveRideForDriver(String driverId) async {
    try {
      final snapshot = await _ridesCollection
          .where('driverId', isEqualTo: driverId)
          .where('status', whereIn: ['accepted', 'arrived', 'in_progress'])
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return RideModel.fromMap(snapshot.docs.first.data(), snapshot.docs.first.id);
      }
    } catch (e) {
      debugPrint('Error getting active driver ride: $e');
    }
    return null;
  }
  // Listen to ride updates and trigger notifications (Client-Side Logic)
  // call this when a user has an active ride
  Stream<RideModel> monitorRideForNotifications(String rideId, NotificationService notificationService) {
    String? lastStatus;
    
    return _ridesCollection.doc(rideId).snapshots().map((doc) {
      if (!doc.exists) throw Exception('Ride not found');
      
      final ride = RideModel.fromMap(doc.data()!, doc.id);
      
      // Check for status changes
      if (lastStatus != null && lastStatus != ride.status) {
         _triggerNotificationForStatus(ride.status, notificationService);
      }
      lastStatus = ride.status; // Update tracker
      
      return ride;
    });
  }

  void _triggerNotificationForStatus(String status, NotificationService notificationService) {
    switch (status) {
      case 'accepted':
        notificationService.showLocalNotification(
          title: 'Driver Found!',
          body: 'A driver has accepted your request.',
          payload: json.encode({'type': 'ride_update', 'status': status}),
        );
        break;
      case 'arrived':
        notificationService.showLocalNotification(
          title: 'Driver Arrived',
          body: 'Your driver is waiting at the pickup location.',
          payload: json.encode({'type': 'ride_update', 'status': status}),
        );
        break;
      case 'in_progress':
        notificationService.showLocalNotification(
          title: 'Ride Started',
          body: 'You are on your way to the destination.',
          payload: json.encode({'type': 'ride_update', 'status': status}),
        );
        break;
      case 'completed':
         notificationService.showLocalNotification(
          title: 'Ride Completed',
          body: 'You have arrived safely. Thank you for riding with us!',
          payload: json.encode({'type': 'ride_update', 'status': status}),
        );
        break;
       case 'cancelled':
         notificationService.showLocalNotification(
          title: 'Ride Cancelled',
          body: 'The ride was cancelled.',
          payload: json.encode({'type': 'ride_update', 'status': status}),
        );
        break;
    }
  }
}
