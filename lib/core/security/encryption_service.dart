import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Service for encrypting sensitive data at rest
class EncryptionService {
  static final EncryptionService _instance = EncryptionService._internal();
  factory EncryptionService() => _instance;
  EncryptionService._internal();

  final _storage = const FlutterSecureStorage();

  // Encryption key stored securely
  static const String _keyStorageKey = 'encryption_master_key';
  encrypt.Key? _masterKey;
  encrypt.IV? _iv;

  /// Initialize encryption service
  Future<void> initialize() async {
    try {
      // Try to get existing key
      final storedKey = await _storage.read(key: _keyStorageKey);

      if (storedKey != null) {
        _masterKey = encrypt.Key.fromBase64(storedKey);
      } else {
        // Generate new key on first run
        _masterKey = encrypt.Key.fromSecureRandom(32);
        await _storage.write(key: _keyStorageKey, value: _masterKey!.base64);
      }

      // Generate IV (initialization vector)
      _iv = encrypt.IV.fromSecureRandom(16);

      debugPrint('EncryptionService: Initialized successfully');
    } catch (e) {
      debugPrint('EncryptionService: Error initializing - $e');
    }
  }

  /// Encrypt sensitive data
  String? encryptData(String plainText) {
    try {
      if (_masterKey == null || _iv == null) {
        debugPrint('EncryptionService: Not initialized');
        return null;
      }

      final encrypter = encrypt.Encrypter(encrypt.AES(_masterKey!));
      final encrypted = encrypter.encrypt(plainText, iv: _iv!);

      // Return IV + encrypted data combined
      return '${_iv!.base64}:${encrypted.base64}';
    } catch (e) {
      debugPrint('EncryptionService: Error encrypting - $e');
      return null;
    }
  }

  /// Decrypt sensitive data
  String? decryptData(String encryptedData) {
    try {
      if (_masterKey == null) {
        debugPrint('EncryptionService: Not initialized');
        return null;
      }

      // Split IV and encrypted data
      final parts = encryptedData.split(':');
      if (parts.length != 2) {
        debugPrint('EncryptionService: Invalid encrypted data format');
        return null;
      }

      final iv = encrypt.IV.fromBase64(parts[0]);
      final encryptedText = encrypt.Encrypted.fromBase64(parts[1]);

      final encrypter = encrypt.Encrypter(encrypt.AES(_masterKey!));
      return encrypter.decrypt(encryptedText, iv: iv);
    } catch (e) {
      debugPrint('EncryptionService: Error decrypting - $e');
      return null;
    }
  }

  /// Hash sensitive data (one-way, for passwords)
  String hashData(String data) {
    final bytes = utf8.encode(data);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Securely store sensitive value
  Future<void> secureStore(String key, String value) async {
    try {
      final encrypted = encryptData(value);
      if (encrypted != null) {
        await _storage.write(key: key, value: encrypted);
      }
    } catch (e) {
      debugPrint('EncryptionService: Error storing - $e');
    }
  }

  /// Securely retrieve value
  Future<String?> secureRetrieve(String key) async {
    try {
      final encrypted = await _storage.read(key: key);
      if (encrypted != null) {
        return decryptData(encrypted);
      }
      return null;
    } catch (e) {
      debugPrint('EncryptionService: Error retrieving - $e');
      return null;
    }
  }

  /// Delete secure value
  Future<void> secureDelete(String key) async {
    try {
      await _storage.delete(key: key);
    } catch (e) {
      debugPrint('EncryptionService: Error deleting - $e');
    }
  }

  /// Clear all secure storage
  Future<void> clearAll() async {
    try {
      await _storage.deleteAll();
    } catch (e) {
      debugPrint('EncryptionService: Error clearing all - $e');
    }
  }
}
