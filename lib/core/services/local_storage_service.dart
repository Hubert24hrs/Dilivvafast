import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:fast_delivery/core/models/ride_model.dart';
import 'package:fast_delivery/core/models/user_model.dart';

/// Local storage service using Hive for offline data caching
class LocalStorageService {
  static final LocalStorageService _instance = LocalStorageService._internal();
  factory LocalStorageService() => _instance;
  LocalStorageService._internal();

  static const String _userBoxName = 'user_cache';
  static const String _ridesBoxName = 'rides_cache';
  static const String _settingsBoxName = 'settings';
  static const String _offlineActionsBoxName = 'offline_actions';

  Box? _userBox;
  Box? _ridesBox;
  Box? _settingsBox;
  Box? _offlineActionsBox;

  /// Initialize Hive and open boxes
  Future<void> initialize() async {
    try {
      await Hive.initFlutter();
      
      // Register adapters if needed (for custom types)
      // Hive.registerAdapter(RideModelAdapter());
      
      _userBox = await Hive.openBox(_userBoxName);
      _ridesBox = await Hive.openBox(_ridesBoxName);
      _settingsBox = await Hive.openBox(_settingsBoxName);
      _offlineActionsBox = await Hive.openBox(_offlineActionsBoxName);
      
      debugPrint('LocalStorageService: Initialized successfully');
    } catch (e) {
      debugPrint('LocalStorageService: Error initializing - $e');
    }
  }

  // ==================== User Data ====================
  
  /// Cache user data
  Future<void> cacheUser(UserModel user) async {
    try {
      await _userBox?.put('current_user', user.toMap());
      debugPrint('LocalStorageService: User cached');
    } catch (e) {
      debugPrint('LocalStorageService: Error caching user - $e');
    }
  }

  /// Get cached user
  UserModel? getCachedUser() {
    try {
      final data = _userBox?.get('current_user');
      if (data != null) {
        return UserModel.fromMap(Map<String, dynamic>.from(data), data['id']);
      }
      return null;
    } catch (e) {
      debugPrint('LocalStorageService: Error getting cached user - $e');
      return null;
    }
  }

  /// Clear user cache
  Future<void> clearUserCache() async {
    try {
      await _userBox?.clear();
    } catch (e) {
      debugPrint('LocalStorageService: Error clearing user cache - $e');
    }
  }

  // ==================== Ride History ====================
  
  /// Cache ride
  Future<void> cacheRide(RideModel ride) async {
    try {
      await _ridesBox?.put(ride.id, ride.toMap());
      debugPrint('LocalStorageService: Ride ${ride.id} cached');
    } catch (e) {
      debugPrint('LocalStorageService: Error caching ride - $e');
    }
  }

  /// Get cached ride
  RideModel? getCachedRide(String rideId) {
    try {
      final data = _ridesBox?.get(rideId);
      if (data != null) {
        return RideModel.fromMap(Map<String, dynamic>.from(data), rideId);
      }
      return null;
    } catch (e) {
      debugPrint('LocalStorageService: Error getting cached ride - $e');
      return null;
    }
  }

  /// Get all cached rides
  List<RideModel> getAllCachedRides() {
    try {
      final rides = <RideModel>[];
      for (var key in _ridesBox?.keys ?? []) {
        final data = _ridesBox?.get(key);
        if (data != null) {
          rides.add(RideModel.fromMap(Map<String, dynamic>.from(data), key));
        }
      }
      return rides..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (e) {
      debugPrint('LocalStorageService: Error getting all rides - $e');
      return [];
    }
  }

  /// Clear ride cache
  Future<void> clearRideCache() async {
    try {
      await _ridesBox?.clear();
    } catch (e) {
      debugPrint('LocalStorageService: Error clearing ride cache - $e');
    }
  }

  // ==================== Settings ====================
  
  /// Save setting
  Future<void> saveSetting(String key, dynamic value) async {
    try {
      await _settingsBox?.put(key, value);
    } catch (e) {
      debugPrint('LocalStorageService: Error saving setting - $e');
    }
  }

  /// Get setting
  T? getSetting<T>(String key, {T? defaultValue}) {
    try {
      return _settingsBox?.get(key, defaultValue: defaultValue) as T?;
    } catch (e) {
      debugPrint('LocalStorageService: Error getting setting - $e');
      return defaultValue;
    }
  }

  // ==================== Offline Actions Queue ====================
  
  /// Queue offline action
  Future<void> queueOfflineAction(Map<String, dynamic> action) async {
    try {
      final actions = _offlineActionsBox?.get('actions', defaultValue: <Map>[]) as List;
      actions.add(action);
      await _offlineActionsBox?.put('actions', actions);
      debugPrint('LocalStorageService: Action queued');
    } catch (e) {
      debugPrint('LocalStorageService: Error queuing action - $e');
    }
  }

  /// Get all offline actions
  List<Map<String, dynamic>> getOfflineActions() {
    try {
      final actions = _offlineActionsBox?.get('actions', defaultValue: <Map>[]) as List;
      return actions.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (e) {
      debugPrint('LocalStorageService: Error getting actions - $e');
      return [];
    }
  }

  /// Clear offline actions
  Future<void> clearOfflineActions() async {
    try {
      await _offlineActionsBox?.delete('actions');
    } catch (e) {
      debugPrint('LocalStorageService: Error clearing actions - $e');
    }
  }

  // ==================== General ====================
  
  /// Clear all caches
  Future<void> clearAll() async {
    try {
      await _userBox?.clear();
      await _ridesBox?.clear();
      await _settingsBox?.clear();
      await _offlineActionsBox?.clear();
      debugPrint('LocalStorageService: All caches cleared');
    } catch (e) {
      debugPrint('LocalStorageService: Error clearing all - $e');
    }
  }

  /// Get cache size info
  Map<String, int> getCacheInfo() {
    return {
      'users': _userBox?.length ?? 0,
      'rides': _ridesBox?.length ?? 0,
      'settings': _settingsBox?.length ?? 0,
      'offline_actions': (_offlineActionsBox?.get('actions', defaultValue: <Map>[]) as List).length,
    };
  }

  /// Close all boxes (call on app dispose)
  Future<void> close() async {
    try {
      await _userBox?.close();
      await _ridesBox?.close();
      await _settingsBox?.close();
      await _offlineActionsBox?.close();
      debugPrint('LocalStorageService: All boxes closed');
    } catch (e) {
      debugPrint('LocalStorageService: Error closing boxes - $e');
    }
  }
}
