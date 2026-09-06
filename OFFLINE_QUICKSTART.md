# ⚡ Offline Support - Quick Start

## What You Get

Your app now works **completely offline** with automatic sync when back online!

- ✅ Works without internet
- ✅ All operations queue locally
- ✅ Auto-syncs when connection returns
- ✅ Manual retry for failed ops
- ✅ Real-time sync status

---

## 3 Steps to Enable

### Step 1: Install Dependencies
```bash
flutter pub get
```

This installs:
- `connectivity_plus` - Network monitoring
- `sqflite` - Local queue database  
- `synchronized` - Thread-safe operations

### Step 2: Update main.dart
Copy this initialization code to your `_MyAppState.initState()`:

```dart
// Import required services
import 'services/offline_queue_service.dart';
import 'services/connectivity_service.dart';
import 'services/sync_service.dart';
import 'providers/sync_provider.dart';

// In initState():
Future<void> _initializeOfflineServices() async {
  // Initialize services
  _connectivityService = ConnectivityService();
  await _connectivityService.initialize();
  
  _queueService = OfflineQueueService();
  _apiClient = ApiClient(queueService: _queueService);
  _syncService = SyncService(_queueService, _apiClient);
  _syncProvider = SyncProvider(_syncService);

  // Auto-sync when connection restored
  _connectivityService.connectionStatus.listen((isOnline) {
    if (isOnline) {
      _apiClient.setOnlineStatus(true);
      _syncProvider.startSync();
    } else {
      _apiClient.setOnlineStatus(false);
    }
  });
}
```

Then add to `MultiProvider`:
```dart
MultiProvider(
  providers: [
    ChangeNotifierProvider.value(value: _syncProvider),
    // ... your other providers
  ],
  child: MaterialApp(...),
)
```

### Step 3: Add UI Indicator (Optional)
Add this to your AppBar to show sync status:

```dart
Consumer<SyncProvider>(
  builder: (context, syncProvider, _) {
    if (syncProvider.hasPendingOperations) {
      return Chip(
        label: Text('${syncProvider.pendingCount} pending'),
        icon: Icon(Icons.cloud_upload),
      );
    }
    return SizedBox.shrink();
  },
)
```

---

## How It Works

### When User Adds Product (Offline)
```
1. User taps "Add Product"
2. ApiClient detects offline ✓
3. Operation queued to SQLite ✓
4. UI shows "Added (will sync)" ✓
5. Data available locally ✓
```

### When Connection Returns
```
1. ConnectivityService detects online ✓
2. SyncService retrieves pending ops ✓
3. Resends to server (POST/PUT/DELETE) ✓
4. Marks synced ✓
5. UI updates status ✓
```

---

## That's It! 🎉

**No changes needed to existing code!**

Your existing `stockProvider.addProduct()` calls automatically:
- Queue when offline
- Sync when online
- Retry on failure
- Show UI status

---

## Debugging

### Check Pending Operations
```dart
final stats = await queueService.getQueueStats();
print('Pending: ${stats['pending']}, Failed: ${stats['failed']}');
```

### View Failed Ops
```dart
final failed = await queueService.getFailedOperations();
for (final op in failed) {
  print('${op.operationType}: ${op.errorMessage}');
}
```

### Manual Sync
```dart
Consumer<SyncProvider>(
  builder: (context, sync, _) => ElevatedButton(
    onPressed: () => sync.startSync(),
    child: Text('Sync Now'),
  ),
)
```

---

## Production Ready ✅

- SQLite queue persists across app restarts
- Max 5 auto-retries per operation
- Failed ops available for manual retry
- Error messages logged for debugging
- Works on all platforms (iOS/Android/Web/Desktop)

---

## Full Documentation

- **OFFLINE_SYNC_COMPLETE.md** - Complete feature overview
- **OFFLINE_SYNC_GUIDE.md** - Detailed usage guide  
- **OFFLINE_INTEGRATION_EXAMPLE.dart** - Full integration code

---

**Your app is now offline-first! 🚀**
