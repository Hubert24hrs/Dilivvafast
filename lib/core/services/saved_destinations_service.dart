import 'package:cloud_firestore/cloud_firestore.dart';

class SavedDestinationsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get saved destinations for a user
  Stream<List<SavedDestination>> getSavedDestinations(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('savedDestinations')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SavedDestination.fromFirestore(doc))
            .toList());
  }

  // Add a saved destination
  Future<void> saveDestination(String userId, SavedDestination destination) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('savedDestinations')
        .add(destination.toMap());
  }

  // Delete a saved destination
  Future<void> deleteDestination(String userId, String destinationId) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('savedDestinations')
        .doc(destinationId)
        .delete();
  }

  // Update a saved destination
  Future<void> updateDestination(String userId, String destinationId, SavedDestination destination) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('savedDestinations')
        .doc(destinationId)
        .update(destination.toMap());
  }
}

class SavedDestination {
  final String? id;
  final String name; // e.g., "Home", "Work", "Gym"
  final String address;
  final double latitude;
  final double longitude;
  final String? icon; // Icon name
  final DateTime createdAt;

  SavedDestination({
    this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.icon,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory SavedDestination.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SavedDestination(
      id: doc.id,
      name: data['name'] ?? '',
      address: data['address'] ?? '',
      latitude: (data['latitude'] ?? 0.0).toDouble(),
      longitude: (data['longitude'] ?? 0.0).toDouble(),
      icon: data['icon'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'icon': icon,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
