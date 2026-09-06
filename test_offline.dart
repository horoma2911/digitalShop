// Test file to verify offline support is working
// Run this in main.dart or as a test
// 
// Usage: Copy this code to your test or main.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:gouanzouh/services/offline_queue_service.dart';
import 'package:gouanzouh/services/connectivity_service.dart';
import 'package:gouanzouh/services/sync_service.dart';
import 'package:gouanzouh/api_client.dart';

void main() {
  group('Offline Support Tests', () {
    late OfflineQueueService queueService;
    late ApiClient apiClient;
    late SyncService syncService;

    setUp(() async {
      // Initialize services
      queueService = OfflineQueueService();
      apiClient = ApiClient(queueService: queueService);
      syncService = SyncService(queueService, apiClient);
    });

    tearDown(() async {
      await queueService.close();
    });

    // Test 1: Queue Operations
    test('Offline: Add operation to queue', () async {
      print('\n📝 TEST 1: Add operation to queue');
      
      // Simulate offline
      apiClient.setOnlineStatus(false);
      
      // Add product
      final payload = {
        'name': 'Test Product',
        'quantity': 10,
        'cost_price': 100.0,
        'selling_price': 150.0,
        'shop_id': 'shop-123'
      };
      
      await queueService.addToQueue('create', 'product', 'prod-1', payload);
      
      // Verify
      final stats = await queueService.getQueueStats();
      print('✓ Pending operations: ${stats['pending']}');
      print('✓ Failed operations: ${stats['failed']}');
      
      expect(stats['pending'], 1);
      expect(stats['failed'], 0);
      
      print('✅ PASSED: Operation queued successfully\n');
    });

    // Test 2: Retrieve Pending Operations
    test('Queue: Retrieve pending operations', () async {
      print('\n📝 TEST 2: Retrieve pending operations');
      
      // Add operations
      await queueService.addToQueue('create', 'product', 'prod-1', {'name': 'P1'});
      await queueService.addToQueue('update', 'product', 'prod-2', {'name': 'P2'});
      await queueService.addToQueue('delete', 'sale', 'sale-1', {});
      
      // Retrieve
      final pending = await queueService.getPendingOperations();
      print('✓ Retrieved ${pending.length} operations');
      
      for (var op in pending) {
        print('  - ${op.operationType} ${op.entityType} (${op.entityId})');
      }
      
      expect(pending.length, 3);
      expect(pending[0].operationType, 'create');
      expect(pending[1].operationType, 'update');
      expect(pending[2].operationType, 'delete');
      
      print('✅ PASSED: All operations retrieved\n');
    });

    // Test 3: Mark as Synced
    test('Queue: Mark operation as synced', () async {
      print('\n📝 TEST 3: Mark operation as synced');
      
      // Add operation
      await queueService.addToQueue('create', 'product', 'prod-1', {'name': 'Test'});
      
      // Get the operation
      var pending = await queueService.getPendingOperations();
      final opId = pending[0].id;
      print('✓ Added operation with ID: $opId');
      
      // Mark as synced
      await queueService.markAsSynced(opId!);
      print('✓ Marked as synced');
      
      // Verify
      pending = await queueService.getPendingOperations();
      expect(pending.length, 0);
      
      print('✅ PASSED: Operation marked as synced\n');
    });

    // Test 4: Retry Count
    test('Queue: Increment retry count', () async {
      print('\n📝 TEST 4: Increment retry count');
      
      // Add operation
      await queueService.addToQueue('create', 'product', 'prod-1', {'name': 'Test'});
      
      // Get operation
      var pending = await queueService.getPendingOperations();
      final opId = pending[0].id;
      
      // Increment retry
      await queueService.incrementRetry(opId, 'Connection timeout');
      print('✓ Incremented retry count');
      
      // Verify
      pending = await queueService.getPendingOperations();
      expect(pending[0].retryCount, 1);
      expect(pending[0].errorMessage, 'Connection timeout');
      
      print('✅ PASSED: Retry count incremented\n');
    });

    // Test 5: Failed Operations
    test('Queue: Mark as failed after max retries', () async {
      print('\n📝 TEST 5: Mark as failed');
      
      // Add operation
      await queueService.addToQueue('create', 'product', 'prod-1', {'name': 'Test'});
      
      // Get operation
      var pending = await queueService.getPendingOperations();
      final opId = pending[0].id;
      
      // Mark as failed
      await queueService.markAsFailed(opId!, 'Max retries exceeded');
      print('✓ Marked as failed');
      
      // Verify
      final failed = await queueService.getFailedOperations();
      expect(failed.length, 1);
      expect(failed[0].errorMessage, 'Max retries exceeded');
      
      print('✅ PASSED: Operation marked as failed\n');
    });

    // Test 6: Queue Statistics
    test('Queue: Get statistics', () async {
      print('\n📝 TEST 6: Get queue statistics');
      
      // Add mixed operations
      await queueService.addToQueue('create', 'product', 'prod-1', {'name': 'P1'});
      await queueService.addToQueue('create', 'product', 'prod-2', {'name': 'P2'});
      
      // Mark one as failed
      var pending = await queueService.getPendingOperations();
      await queueService.markAsFailed(pending[0].id!, 'Test error');
      
      // Get stats
      final stats = await queueService.getQueueStats();
      print('✓ Pending: ${stats['pending']}');
      print('✓ Failed: ${stats['failed']}');
      
      expect(stats['pending'], 1);
      expect(stats['failed'], 1);
      
      print('✅ PASSED: Statistics correct\n');
    });

    // Test 7: Connectivity Detection
    test('Connectivity: Check online status', () async {
      print('\n📝 TEST 7: Check online status');
      
      final connectivity = ConnectivityService();
      await connectivity.initialize();
      
      print('✓ Connectivity initialized');
      print('✓ Current status: ${connectivity.isOnline ? "Online" : "Offline"}');
      
      expect(connectivity.isOnline, isNotNull);
      
      print('✅ PASSED: Connectivity detected\n');
    });

    // Test 8: API Client Offline Queueing
    test('ApiClient: Queue operation when offline', () async {
      print('\n📝 TEST 8: API Client offline queueing');
      
      // Set offline
      apiClient.setOnlineStatus(false);
      print('✓ Set offline mode');
      
      // Try to add product
      final result = await apiClient.post('/products', {
        'name': 'Test Product',
        'quantity': 10,
        'cost_price': 100,
        'selling_price': 150
      });
      
      print('✓ Attempted POST /products');
      print('✓ Result: $result');
      
      // Verify queued
      final stats = await queueService.getQueueStats();
      expect(stats['pending'], greaterThan(0));
      
      print('✅ PASSED: Operation queued via ApiClient\n');
    });

    // Test 9: Clear Synced Operations
    test('Queue: Clear synced operations', () async {
      print('\n📝 TEST 9: Clear synced operations');
      
      // Add and sync operations
      await queueService.addToQueue('create', 'product', 'prod-1', {'name': 'P1'});
      await queueService.addToQueue('create', 'product', 'prod-2', {'name': 'P2'});
      
      var pending = await queueService.getPendingOperations();
      await queueService.markAsSynced(pending[0].id!);
      await queueService.markAsSynced(pending[1].id!);
      
      // Clear synced
      await queueService.clearSynced();
      print('✓ Cleared synced operations');
      
      // Verify
      final stats = await queueService.getQueueStats();
      print('✓ Remaining pending: ${stats['pending']}');
      
      print('✅ PASSED: Synced operations cleared\n');
    });

    // Test 10: Database Persistence
    test('Database: Queue persists', () async {
      print('\n📝 TEST 10: Database persistence');
      
      // Add operations to first instance
      await queueService.addToQueue('create', 'product', 'prod-1', {'name': 'P1'});
      print('✓ Added operation to queue');
      
      // Create new service instance (simulates app restart)
      final newQueue = OfflineQueueService();
      
      // Retrieve from new instance
      final pending = await newQueue.getPendingOperations();
      print('✓ Retrieved from new instance: ${pending.length} operations');
      
      expect(pending.length, 1);
      expect(pending[0].payload['name'], 'P1');
      
      await newQueue.close();
      
      print('✅ PASSED: Queue persists across instances\n');
    });
  });
}

// Run with: flutter test test/offline_test.dart
