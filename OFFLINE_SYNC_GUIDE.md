# Offline Support & Sync Documentation

## Overview

Gouanzouh now supports complete offline functionality. Users can:
- Work without internet connection
- All operations are queued locally
- Automatic sync when connection returns
- Manual retry for failed operations
- Real-time sync status tracking

---

## Architecture

### Components

1. **OfflineQueueService** (`lib/services/offline_queue_service.dart`)
   - SQLite database for storing pending operations
   - Queue management (add, retrieve, update status)
   - Operation statuses: pending, synced, failed

2. **ConnectivityService** (`lib/services/connectivity_service.dart`)
   - Monitors network connectivity
   - Provides real-time status stream
   - Detects online/offline transitions

3. **SyncService** (`lib/services/sync_service.dart`)
   - Orchestrates syncing pending operations
   - Handles retry logic with configurable max retries
   - Converts queue entries to API calls
   - Manages operation lifecycle

4. **SyncProvider** (`lib/providers/sync_provider.dart`)
   - Provider for UI integration
   - Tracks sync state and statistics
   - Exposes queue stats and failed operations

5. **ApiClient** (updated `lib/api_client.dart`)
   - Detects online/offline status
   - Queues operations when offline
   - Falls back to queue on connection error

---

## Data Flow

### Offline Operation

```
User Action (Create/Update/Delete)
         ↓
    ApiClient
         ↓
   Check isOnline?
    /            \
  YES            NO
   ↓              ↓
  POST to      Add to
  Server      Queue (SQLite)
   ↓              ↓
  Success?   Notify User
   /  \       (Offline Mode)
YES   NO
 ↓     ↓
Return Queue as backup
```

### Online Sync

```
Connection Restored
         ↓
   SyncService
         ↓
  Get Pending Ops
         ↓
  For Each Operation:
    ├─ Extract payload
    ├─ Determine type (product/sale/expense)
    ├─ POST/PUT/DELETE to server
    └─ Mark as synced or retry
         ↓
  Clear completed syncs
         ↓
  Notify SyncProvider
         ↓
  UI Updates
```

---

## Queue Schema

The offline queue stores:

```sql
CREATE TABLE sync_queue (
  id INTEGER PRIMARY KEY,
  operation_type TEXT,    -- 'create', 'update', 'delete'
  entity_type TEXT,       -- 'product', 'sale', 'expense', 'shop'
  entity_id TEXT,         -- UUID of entity
  payload TEXT,           -- JSON serialized data
  created_at TEXT,        -- ISO 8601 timestamp
  retry_count INTEGER,    -- Number of retry attempts
  error_message TEXT,     -- Last error
  status TEXT             -- 'pending', 'synced', 'failed'
)
```

---

## Usage in Providers

### Example: Stock Provider (Offline-Aware)

```dart
// Instead of direct API call, use ApiClient with offline support
class StockProvider extends ChangeNotifier {
  final ApiClient apiClient;
  bool isOnline = true;

  Future<void> addProduct(Product product) async {
    try {
      final result = await apiClient.addProduct({
        'name': product.name,
        'quantity': product.quantity,
        'cost_price': product.costPrice,
        'selling_price': product.sellingPrice,
        'shop_id': product.shopId,
      });

      // Check if operation was queued
      if (result['offline'] == true && result['queued'] == true) {
        // Operation queued locally
        _products.add(product); // Add to local cache
        notifyListeners();
        showMessage('Added (will sync when online)');
      } else if (result['id'] != null) {
        // Successfully created on server
        _products.add(product);
        notifyListeners();
        showMessage('Added successfully');
      }
    } catch (e) {
      // Operation queued on error
      _products.add(product);
      notifyListeners();
      showMessage('Added locally (sync pending)');
    }
  }
}
```

---

## UI Integration

### Show Sync Status Widget

```dart
// In your main page
Consumer<SyncProvider>(
  builder: (context, syncProvider, _) {
    if (syncProvider.hasPendingOperations) {
      return FloatingActionButton.extended(
        onPressed: () => syncProvider.startSync(),
        label: Text('Sync ${syncProvider.pendingCount} items'),
        icon: Icon(Icons.cloud_upload),
      );
    }
    
    if (syncProvider.hasFailedOperations) {
      return Chip(
        label: Text('${syncProvider.failedCount} failed'),
        avatar: Icon(Icons.error),
        backgroundColor: Colors.red.shade100,
      );
    }
    
    return SizedBox.shrink();
  },
)
```

### Handle Connectivity Changes

```dart
// In main.dart or app initialization
class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late ConnectivityService _connectivity;
  late SyncService _syncService;
  late StreamSubscription _subscription;

  @override
  void initState() {
    super.initState();
    _setupOfflineSupport();
  }

  void _setupOfflineSupport() {
    _connectivity = ConnectivityService();
    _syncService = SyncService(
      OfflineQueueService(),
      ApiClient(),
    );

    // Listen for connection changes
    _subscription = _connectivity.connectionStatus.listen((isOnline) {
      if (isOnline) {
        _apiClient.setOnlineStatus(true);
        _syncService.syncPendingOperations();
      } else {
        _apiClient.setOnlineStatus(false);
      }
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SyncProvider(_syncService)),
        // ... other providers
      ],
      child: MaterialApp(...),
    );
  }
}
```

---

## Sync Triggering

### Automatic Sync

When connection is restored:
```dart
_connectivity.connectionStatus.listen((isOnline) {
  if (isOnline) {
    syncProvider.startSync(); // Auto-trigger sync
  }
});
```

### Manual Sync

User can manually trigger sync:
```dart
ElevatedButton(
  onPressed: () => syncProvider.startSync(),
  child: Text('Sync Now'),
)
```

### Periodic Sync (Optional)

Add to main.dart:
```dart
// Attempt sync every 30 seconds
Timer.periodic(Duration(seconds: 30), (_) {
  if (_connectivity.isOnline && !syncProvider.isSyncing) {
    syncProvider.startSync();
  }
});
```

---

## Handling Failed Operations

### View Failed Operations

```dart
Consumer<SyncProvider>(
  builder: (context, syncProvider, _) {
    return FutureBuilder<List<QueueEntry>>(
      future: syncProvider.getFailedOperations(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return SizedBox.shrink();
        
        return ListView.builder(
          itemCount: snapshot.data!.length,
          itemBuilder: (context, i) {
            final op = snapshot.data![i];
            return ListTile(
              title: Text('${op.operationType} ${op.entityType}'),
              subtitle: Text(op.errorMessage ?? 'Unknown error'),
              trailing: IconButton(
                icon: Icon(Icons.retry),
                onPressed: () => syncProvider.retryFailedOperation(op.id!),
              ),
            );
          },
        );
      },
    );
  },
)
```

### Automatic Retry

Retries are configured with:
- Max retries: 5 attempts
- Retry happens on connectivity restore
- Manual retry available for each operation
- Error message logged for debugging

---

## Queue Database

### Location
- Android: `/data/data/com.gouanzouh.app/databases/gouanzouh_queue.db`
- iOS: `Library/Application Support/gouanzouh_queue.db`
- Linux/Windows: Application support directory

### Statistics Query

```dart
final stats = await syncProvider.getSyncStatus();
print('Pending: ${stats['pending']}');
print('Failed: ${stats['failed']}');
```

### Manual Cleanup

```dart
// Clear all synced operations (after successful sync)
await queueService.clearSynced();
```

---

## Error Handling

### Network Errors
- Operation queued automatically
- User notified: "Added (will sync when online)"
- Retried when connection restored

### Server Errors (4xx, 5xx)
- Logged to queue with error message
- After 5 retries, marked as failed
- Manual retry available in failed operations screen

### Validation Errors
- Server response error is stored
- User should fix data before retry
- Error message shown: "Invalid email format"

---

## Best Practices

1. **Always check sync status** before critical operations
2. **Show clear offline indicators** in UI
3. **Auto-sync on app resume** when coming back online
4. **Batch sync** multiple operations at once
5. **Log errors** for debugging failed syncs
6. **Provide manual retry** for failed operations
7. **Clear queue** periodically after successful syncs

---

## Testing Offline Features

### Simulate Offline Mode

```dart
// In development, force offline mode
final apiClient = ApiClient();
apiClient.setOnlineStatus(false); // Simulate offline

// Operations will queue automatically
await apiClient.addProduct({...});

// Check queue
final stats = await queueService.getQueueStats();
assert(stats['pending'] == 1);

// Restore online
apiClient.setOnlineStatus(true);
await syncService.syncPendingOperations();
assert(stats['pending'] == 0);
```

### Manual Queue Inspection

```dart
// Get all pending operations
final pending = await queueService.getPendingOperations();
for (final op in pending) {
  print('${op.operationType} ${op.entityType}: ${op.payload}');
}

// Get failed operations
final failed = await queueService.getFailedOperations();
for (final op in failed) {
  print('Error: ${op.errorMessage}');
}
```

---

## Troubleshooting

### Queue not syncing
- Check `isOnline` status: `apiClient.setOnlineStatus(true)`
- Verify JWT token is set
- Check backend API is running

### Operations marked failed immediately
- Check error message: `op.errorMessage`
- Verify payload format matches backend expectations
- Check JWT token validity

### Queue database getting large
- Call `clearSynced()` after successful syncs
- Implement cleanup job to remove old synced entries
- Monitor database size regularly

---

## Future Enhancements

1. Conflict resolution for concurrent updates
2. Delta sync (only modified fields)
3. Encryption for sensitive queue data
4. Background sync service
5. Queue analytics and metrics
6. Customizable retry strategies
7. Batch API endpoint optimization

---

## Files Modified/Created

- ✅ `lib/services/offline_queue_service.dart` - Queue management
- ✅ `lib/services/connectivity_service.dart` - Connection monitoring
- ✅ `lib/services/sync_service.dart` - Sync orchestration
- ✅ `lib/providers/sync_provider.dart` - UI integration
- ✅ `lib/api_client.dart` - Updated with offline support
- ✅ `pubspec.yaml` - Added dependencies (connectivity_plus, sqflite, synchronized)

---

**The app is now fully offline-capable with automatic sync when online!**
