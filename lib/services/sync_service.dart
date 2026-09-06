import 'package:logger/logger.dart';
import 'offline_queue_service.dart';
import '../api_client.dart';

class SyncService {
  final OfflineQueueService _queueService;
  final ApiClient _apiClient;
  final Logger _logger = Logger();
  
  bool _isSyncing = false;
  bool get isSyncing => _isSyncing;

  SyncService(this._queueService, this._apiClient);

  /// Sync all pending operations with server
  Future<void> syncPendingOperations() async {
    if (_isSyncing) return;
    
    _isSyncing = true;
    try {
      final pendingOps = await _queueService.getPendingOperations();
      
      for (final op in pendingOps) {
        try {
          await _syncOperation(op);
        } catch (e) {
          _logger.w('Error syncing ${op.id}: $e');
          if (op.retryCount < 5) {
            await _queueService.incrementRetry(op.id!, e.toString());
          } else {
            await _queueService.markAsFailed(op.id!, 'Max retries exceeded: $e');
          }
        }
      }
      
      // Clear synced operations
      await _queueService.clearSynced();
    } finally {
      _isSyncing = false;
    }
  }

  /// Sync a single operation
  Future<void> _syncOperation(QueueEntry op) async {
    _logger.i('Syncing ${op.operationType} ${op.entityType} ${op.entityId}');
    
    switch (op.entityType) {
      case 'product':
        await _syncProduct(op);
        break;
      case 'sale':
        await _syncSale(op);
        break;
      case 'expense':
        await _syncExpense(op);
        break;
      case 'shop':
        await _syncShop(op);
        break;
    }
    
    await _queueService.markAsSynced(op.id!);
  }

  /// Sync product operation
  Future<void> _syncProduct(QueueEntry op) async {
    final payload = op.payload;
    
    switch (op.operationType) {
      case 'create':
        await _apiClient.post('/products', payload);
        break;
      case 'update':
        await _apiClient.put('/products/${op.entityId}', payload);
        break;
      case 'delete':
        await _apiClient.delete('/products/${op.entityId}');
        break;
    }
  }

  /// Sync sale operation
  Future<void> _syncSale(QueueEntry op) async {
    final payload = op.payload;
    
    switch (op.operationType) {
      case 'create':
        await _apiClient.post('/sales', payload);
        break;
      case 'update':
        await _apiClient.put('/sales/${op.entityId}', payload);
        break;
      case 'delete':
        await _apiClient.delete('/sales/${op.entityId}');
        break;
    }
  }

  /// Sync expense operation
  Future<void> _syncExpense(QueueEntry op) async {
    final payload = op.payload;
    
    switch (op.operationType) {
      case 'create':
        await _apiClient.post('/expenses', payload);
        break;
      case 'update':
        await _apiClient.put('/expenses/${op.entityId}', payload);
        break;
      case 'delete':
        await _apiClient.delete('/expenses/${op.entityId}');
        break;
    }
  }

  /// Sync shop operation
  Future<void> _syncShop(QueueEntry op) async {
    final payload = op.payload;
    
    switch (op.operationType) {
      case 'create':
        await _apiClient.post('/shops', payload);
        break;
      case 'update':
        await _apiClient.put('/shops/${op.entityId}', payload);
        break;
      case 'delete':
        await _apiClient.delete('/shops/${op.entityId}');
        break;
    }
  }

  /// Get sync status
  Future<Map<String, int>> getSyncStatus() async {
    return await _queueService.getQueueStats();
  }

  /// Get failed operations
  Future<List<QueueEntry>> getFailedOperations() async {
    return await _queueService.getFailedOperations();
  }

  /// Retry a specific failed operation
  Future<void> retryFailedOperation(int queueId) async {
    final failedOps = await _queueService.getFailedOperations();
    final op = failedOps.firstWhere((o) => o.id == queueId);
    
    // Reset retry count
    await _queueService.incrementRetry(queueId, null);
    
    try {
      await _syncOperation(op);
    } catch (e) {
      _logger.e('Retry failed for $queueId: $e');
      rethrow;
    }
  }

  /// Clear all synced operations
  Future<void> clearSynced() async {
    await _queueService.clearSynced();
  }
}
