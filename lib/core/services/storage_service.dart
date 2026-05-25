import 'dart:typed_data'; // for Uint8List
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String> uploadProfilePhoto(String userId, Uint8List data) async {
    final ref = _storage.ref().child('users/$userId/profile_photo.jpg');
    // Set metadata for caching/type
    final metadata = SettableMetadata(contentType: 'image/jpeg');
    final uploadTask = ref.putData(data, metadata);
    final snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }

  Future<String> uploadDocument(String userId, String docType, Uint8List data) async {
    final ref = _storage.ref().child('users/$userId/documents/$docType.jpg');
    final metadata = SettableMetadata(contentType: 'image/jpeg');
    final uploadTask = ref.putData(data, metadata);
    final snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }
}

final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});
