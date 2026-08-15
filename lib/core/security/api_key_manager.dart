import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';

import 'package:dilivvafast/core/config/app_config.dart';

/// Secure API key management with obfuscation
class ApiKeyManager {
  static final ApiKeyManager _instance = ApiKeyManager._internal();
  factory ApiKeyManager() => _instance;
  ApiKeyManager._internal();

  /// Get Mapbox access token
  String? getMapboxToken() {
    try {
      final token = AppConfig.instance.mapboxAccessToken;
      return token.isEmpty ? null : token;
    } catch (e) {
      debugPrint('Error getting Mapbox token: $e');
      return null;
    }
  }

  /// Get Paystack public key
  String? getPaystackPublicKey() {
    try {
      final key = AppConfig.instance.paystackPublicKey;
      return key.isEmpty ? null : key;
    } catch (e) {
      debugPrint('Error getting Paystack key: $e');
      return null;
    }
  }

  /// Validate API key format
  bool validateKey(String key) {
    if (key.isEmpty) return false;
    if (key.length < 20) return false;
    return true;
  }

  /// Generate hash for key verification (for integrity checks)
  String generateKeyHash(String key) {
    final bytes = utf8.encode(key);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Check if all required keys are present
  bool areKeysConfigured() {
    final mapboxToken = getMapboxToken();
    final paystackKey = getPaystackPublicKey();

    if (mapboxToken == null || paystackKey == null) {
      debugPrint('Missing required API keys in .env file');
      return false;
    }

    if (!validateKey(mapboxToken) || !validateKey(paystackKey)) {
      debugPrint('Invalid API key format');
      return false;
    }

    return true;
  }

  /// Get all configured keys (for debugging - remove in production)
  Map<String, bool> getKeyStatus() {
    return {
      'mapbox': getMapboxToken() != null,
      'paystack': getPaystackPublicKey() != null,
    };
  }
}
