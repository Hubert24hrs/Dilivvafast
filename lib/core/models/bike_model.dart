import 'package:cloud_firestore/cloud_firestore.dart';

/// Maintenance alert for bikes
class MaintenanceAlert {
  final String type; // 'oil_change', 'tire_check', 'service_due', 'repair'
  final String message;
  final DateTime dueDate;
  final bool isResolved;

  MaintenanceAlert({
    required this.type,
    required this.message,
    required this.dueDate,
    this.isResolved = false,
  });

  factory MaintenanceAlert.fromMap(Map<String, dynamic> data) {
    return MaintenanceAlert(
      type: data['type'] ?? '',
      message: data['message'] ?? '',
      dueDate: data['dueDate'] is Timestamp 
          ? (data['dueDate'] as Timestamp).toDate()
          : DateTime.parse(data['dueDate'] ?? DateTime.now().toIso8601String()),
      isResolved: data['isResolved'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'message': message,
      'dueDate': dueDate.toIso8601String(),
      'isResolved': isResolved,
    };
  }
}

/// Bike model for HP-funded bikes with tracking
class BikeModel {
  final String id; // Format: "BIKE-12345-ABC"
  final String? investorId;
  final String? riderId;
  final String make; // e.g., "Honda"
  final String model; // e.g., "Wave 110"
  final int year;
  final String? plateNumber;
  final String? color;
  final double purchasePrice;
  final GeoPoint? currentLocation;
  final String status; // 'pending_funding', 'funded', 'active', 'repossessed', 'completed'
  final List<MaintenanceAlert> maintenanceAlerts;
  final DateTime? lastServiceDate;
  final double totalKilometers;
  final String? gpsDeviceId; // For real-time tracking
  final String? imageUrl;
  final int totalRides;
  final double totalEarnings;
  final DateTime createdAt;
  final DateTime? updatedAt;

  BikeModel({
    required this.id,
    this.investorId,
    this.riderId,
    required this.make,
    required this.model,
    required this.year,
    this.plateNumber,
    this.color,
    required this.purchasePrice,
    this.currentLocation,
    this.status = 'pending_funding',
    this.maintenanceAlerts = const [],
    this.lastServiceDate,
    this.totalKilometers = 0.0,
    this.gpsDeviceId,
    this.imageUrl,
    this.totalRides = 0,
    this.totalEarnings = 0.0,
    required this.createdAt,
    this.updatedAt,
  });

  /// Generate unique bike ID
  static String generateBikeId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString().substring(5);
    final random = (DateTime.now().microsecond % 1000).toString().padLeft(3, '0');
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ';
    final suffix = List.generate(3, (i) => chars[(DateTime.now().microsecond + i) % chars.length]).join();
    return 'BIKE-$timestamp$random-$suffix';
  }

  String get displayName => '$make $model ($year)';
  
  bool get hasActiveAlerts => maintenanceAlerts.any((a) => !a.isResolved);

  factory BikeModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    DateTime parsedCreatedAt;
    try {
      if (data['createdAt'] is Timestamp) {
        parsedCreatedAt = (data['createdAt'] as Timestamp).toDate();
      } else if (data['createdAt'] is String) {
        parsedCreatedAt = DateTime.parse(data['createdAt']);
      } else {
        parsedCreatedAt = DateTime.now();
      }
    } catch (e) {
      parsedCreatedAt = DateTime.now();
    }

    DateTime? parsedUpdatedAt;
    if (data['updatedAt'] != null) {
      try {
        if (data['updatedAt'] is Timestamp) {
          parsedUpdatedAt = (data['updatedAt'] as Timestamp).toDate();
        } else if (data['updatedAt'] is String) {
          parsedUpdatedAt = DateTime.parse(data['updatedAt']);
        }
      } catch (e) {
        parsedUpdatedAt = null;
      }
    }

    DateTime? parsedLastServiceDate;
    if (data['lastServiceDate'] != null) {
      try {
        if (data['lastServiceDate'] is Timestamp) {
          parsedLastServiceDate = (data['lastServiceDate'] as Timestamp).toDate();
        } else if (data['lastServiceDate'] is String) {
          parsedLastServiceDate = DateTime.parse(data['lastServiceDate']);
        }
      } catch (e) {
        parsedLastServiceDate = null;
      }
    }

    List<MaintenanceAlert> alerts = [];
    if (data['maintenanceAlerts'] != null) {
      alerts = (data['maintenanceAlerts'] as List)
          .map((a) => MaintenanceAlert.fromMap(a))
          .toList();
    }

    return BikeModel(
      id: doc.id,
      investorId: data['investorId'],
      riderId: data['riderId'],
      make: data['make'] ?? '',
      model: data['model'] ?? '',
      year: data['year'] ?? DateTime.now().year,
      plateNumber: data['plateNumber'],
      color: data['color'],
      purchasePrice: (data['purchasePrice'] ?? 0.0).toDouble(),
      currentLocation: data['currentLocation'] as GeoPoint?,
      status: data['status'] ?? 'pending_funding',
      maintenanceAlerts: alerts,
      lastServiceDate: parsedLastServiceDate,
      totalKilometers: (data['totalKilometers'] ?? 0.0).toDouble(),
      gpsDeviceId: data['gpsDeviceId'],
      imageUrl: data['imageUrl'],
      totalRides: data['totalRides'] ?? 0,
      totalEarnings: (data['totalEarnings'] ?? 0.0).toDouble(),
      createdAt: parsedCreatedAt,
      updatedAt: parsedUpdatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'investorId': investorId,
      'riderId': riderId,
      'make': make,
      'model': model,
      'year': year,
      'plateNumber': plateNumber,
      'color': color,
      'purchasePrice': purchasePrice,
      'currentLocation': currentLocation,
      'status': status,
      'maintenanceAlerts': maintenanceAlerts.map((a) => a.toMap()).toList(),
      'lastServiceDate': lastServiceDate?.toIso8601String(),
      'totalKilometers': totalKilometers,
      'gpsDeviceId': gpsDeviceId,
      'imageUrl': imageUrl,
      'totalRides': totalRides,
      'totalEarnings': totalEarnings,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  BikeModel copyWith({
    String? investorId,
    String? riderId,
    String? plateNumber,
    String? color,
    GeoPoint? currentLocation,
    String? status,
    List<MaintenanceAlert>? maintenanceAlerts,
    DateTime? lastServiceDate,
    double? totalKilometers,
    String? gpsDeviceId,
    String? imageUrl,
    int? totalRides,
    double? totalEarnings,
    DateTime? updatedAt,
  }) {
    return BikeModel(
      id: id,
      investorId: investorId ?? this.investorId,
      riderId: riderId ?? this.riderId,
      make: make,
      model: model,
      year: year,
      plateNumber: plateNumber ?? this.plateNumber,
      color: color ?? this.color,
      purchasePrice: purchasePrice,
      currentLocation: currentLocation ?? this.currentLocation,
      status: status ?? this.status,
      maintenanceAlerts: maintenanceAlerts ?? this.maintenanceAlerts,
      lastServiceDate: lastServiceDate ?? this.lastServiceDate,
      totalKilometers: totalKilometers ?? this.totalKilometers,
      gpsDeviceId: gpsDeviceId ?? this.gpsDeviceId,
      imageUrl: imageUrl ?? this.imageUrl,
      totalRides: totalRides ?? this.totalRides,
      totalEarnings: totalEarnings ?? this.totalEarnings,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
