import 'package:flutter/material.dart';

/// Stub storage service for file uploads (Firebase Storage)
class StorageService {
  Future<String?> uploadFile({
    required String path,
    required String filePath,
  }) async {
    debugPrint('StorageService.uploadFile called (stub): $path');
    return null;
  }

  Future<String?> getDownloadUrl(String path) async {
    debugPrint('StorageService.getDownloadUrl called (stub): $path');
    return null;
  }

  Future<void> deleteFile(String path) async {
    debugPrint('StorageService.deleteFile called (stub): $path');
  }
}
