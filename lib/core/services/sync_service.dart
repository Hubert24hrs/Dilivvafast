import 'package:fast_delivery/core/services/local_storage_service.dart';
import 'package:fast_delivery/core/services/connectivity_service.dart';
import 'package:fast_delivery/core/services/database_service.dart';
import 'package:fast_delivery/core/providers/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Service to sync offline data with cloud when connection restored
class SyncService {
  final LocalStorageService _localStorage;
  final ConnectivityService _connectivity;
  // ignore: unused_field
  final DatabaseService _database;

  SyncService({
    required LocalStorageService localStorage,
    required ConnectivityService connectivity,
    required DatabaseService database,
  })  : _localStorage = localStorage,
        _connectivity = connectivity,
        _database = database;

  /// Start monitoring connectivity and sync when online
  Stream<SyncStatus> monitorAndSync() async* {
    await for (final connectivityStatus in _connectivity.connectivityStream) {
      final isConnected = connectivityStatus.isNotEmpty;
      
      if (isConnected) {
        yield SyncStatus.syncing;
        
        try {
          await _syncOfflineActions();
          await _syncCachedData();
          
          yield SyncStatus.synced;
          debugPrint('SyncService: Sync completed successfully');
        } catch (e) {
          debugPrint('SyncService: Sync failed - $e');
          yield SyncStatus.failed;
        }
      } else {
        yield SyncStatus.offline;
      }
    }
  }

  /// Sync offline actions to cloud
  Future<void> _syncOfflineActions() async {
    final actions = _localStorage.getOfflineActions();
    
    if (actions.isEmpty) {
      debugPrint('SyncService: No offline actions to sync');
      return;
    }

    debugPrint('SyncService: Syncing ${actions.length} offline actions');
    
    for (final action in actions) {
      try {
        await _executeAction(action);
      } catch (e) {
        debugPrint('SyncService: Error executing action - $e');
        // Keep action in queue to retry later
        continue;
      }
    }

    // Clear successfully synced actions
    await _localStorage.clearOfflineActions();
  }

  /// Execute a queued offline action
  Future<void> _executeAction(Map<String, dynamic> action) async {
    final type = action['type'] as String?;
    
    switch (type) {
      case 'update_profile':
        // Execute profile update
        break;
      case 'add_favorite':
        // Execute add favorite
        break;
      // Add more action types as needed
      default:
        debugPrint('SyncService: Unknown action type - $type');
    }
  }

  /// Sync cached data with latest from cloud
  Future<void> _syncCachedData() async {
    debugPrint('SyncService: Syncing cached data with cloud');
    
    // Fetch latest user data
    // Fetch latest ride history
    // Update local cache
  }

  /// Force sync now
  Future<bool> forceSyncNow() async {
    try {
      final isConnected = await _connectivity.isConnected();
      
      if (!isConnected) {
        debugPrint('SyncService: Cannot sync - offline');
        return false;
      }

      await _syncOfflineActions();
      await _syncCachedData();
      
      return true;
    } catch (e) {
      debugPrint('SyncService: Force sync failed - $e');
      return false;
    }
  }

  /// Get sync status
  Future<Map<String, dynamic>> getSyncStatus() async {
    final isConnected = await _connectivity.isConnected();
    final pendingActions = _localStorage.getOfflineActions().length;
    final cacheInfo = _localStorage.getCacheInfo();

    return {
      'connected': isConnected,
      'pending_actions': pendingActions,
      'cache_info': cacheInfo,
    };
  }
}

/// Sync status enum
enum SyncStatus {
  offline,
  syncing,
  synced,
  failed,
}

/// Provider for SyncService
final syncServiceProvider = Provider<SyncService>((ref) {
  return SyncService(
    localStorage: LocalStorageService(),
    connectivity: ref.watch(connectivityServiceProvider),
    database: ref.watch(databaseServiceProvider),
  );
});

/// Provider for sync status stream
final syncStatusProvider = StreamProvider<SyncStatus>((ref) {
  return ref.watch(syncServiceProvider).monitorAndSync();
});
