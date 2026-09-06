import 'package:flutter/material.dart';
import '../services/sync_service.dart';
import '../services/offline_queue_service.dart';

class SyncProvider extends ChangeNotifier {
  final SyncService _syncService;
  
  bool _isSyncing = false;
  Map<String, int> _queueStats = {'pending': 0, 'failed': 0};
  String _syncMessage = '';
  bool _hasFailedOperations = false;

  bool get isSyncing => _isSyncing;
  Map<String, int> get queueStats => _queueStats;
  String get syncMessage => _syncMessage;
  bool get hasFailedOperations => _hasFailedOperations;
  bool get hasPendingOperations => _queueStats['pending']! > 0;
  int get pendingCount => _queueStats['pending'] ?? 0;
  int get failedCount => _queueStats['failed'] ?? 0;

  SyncProvider(this._syncService);

  /// Refresh queue statistics
  Future<void> refreshQueueStats() async {
    _queueStats = await _syncService.getSyncStatus();
    final failed = await _syncService.getFailedOperations();
    _hasFailedOperations = failed.isNotEmpty;
    notifyListeners();
  }

  /// Start sync process
  Future<void> startSync() async {
    if (_isSyncing) return;
    
    _isSyncing = true;
    _syncMessage = 'Syncing...';
    notifyListeners();

    try {
      await _syncService.syncPendingOperations();
      await refreshQueueStats();
      
      if (_queueStats['pending'] == 0 && _queueStats['failed'] == 0) {
        _syncMessage = '✓ All synced';
      } else if (_queueStats['failed']! > 0) {
        _syncMessage = '⚠ ${_queueStats['failed']} failed operations';
      }
    } catch (e) {
      _syncMessage = '✗ Sync failed: $e';
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  /// Retry a failed operation
  Future<void> retryFailedOperation(int queueId) async {
    try {
      await _syncService.retryFailedOperation(queueId);
      _syncMessage = 'Operation synced successfully';
      await refreshQueueStats();
    } catch (e) {
      _syncMessage = 'Retry failed: $e';
    }
    notifyListeners();
  }

  /// Get failed operations
  Future<List<QueueEntry>> getFailedOperations() async {
    return await _syncService.getFailedOperations();
  }

  /// Clear sync message
  void clearMessage() {
    _syncMessage = '';
    notifyListeners();
  }
}
