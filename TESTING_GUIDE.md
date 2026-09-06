# 🧪 Testing Offline Support - Complete Guide

## Prerequisites
- Flutter environment ready ✓
- All dependencies installed ✓
- App ready to run

## Testing Scenarios

### Test 1: Basic Offline Queue (5 min)

**Goal**: Verify operations queue when offline

**Steps**:
```bash
# 1. Start app in debug mode
cd C:\Users\VICTUS\Pictures\gouanzouh
flutter run -v

# 2. Once app loads, simulate offline:
# In Flutter DevTools (or code):
# apiClient.setOnlineStatus(false);

# 3. Try adding a product
# → Should see "Added (will sync)" message

# 4. Check queue:
# final stats = await queueService.getQueueStats();
# print('Pending: ${stats['pending']}'); // Should be 1

# 5. Go back online:
# apiClient.setOnlineStatus(true);

# 6. Should auto-sync
# → Watch operations sync
```

**Expected Result**:
- Operation queued ✓
- Queue count increases ✓
- Auto-syncs on reconnect ✓

---

### Test 2: Offline Queue UI Indicators (5 min)

**Goal**: Verify UI shows pending/failed counts

**Steps**:
```
1. Look at AppBar
   → Should show sync status (if integrated)
   
2. Go offline
   → UI should update to show "offline mode"
   
3. Add 3 products while offline
   → Pending count should increase
   → UI shows "3 pending"
   
4. Go online
   → Watch pending count decrease
   → UI shows "✓ Synced"
```

**Expected Result**:
- Pending count displayed ✓
- Count updates real-time ✓
- Synced status shown ✓

---

### Test 3: Failed Operation Recovery (10 min)

**Goal**: Test failed operation retry

**Steps**:
```
1. Go offline
2. Add product with invalid data (optional)
3. Go online
4. Check if sync retries automatically
5. View failed operations:

   final failed = await queueService.getFailedOperations();
   for (var op in failed) {
     print('Error: ${op.errorMessage}');
   }

6. Manual retry:
   await syncProvider.retryFailedOperation(op.id);
```

**Expected Result**:
- Failed ops marked ✓
- Error message logged ✓
- Manual retry works ✓

---

### Test 4: App Restart Persistence (5 min)

**Goal**: Verify operations survive app restart

**Steps**:
```
1. Go offline
2. Add 2 products (offline)
3. Close app completely
4. Reopen app
5. Check queue stats:
   final stats = await queueService.getQueueStats();
   // Should still show 2 pending
6. Go online
7. Should auto-sync
```

**Expected Result**:
- Queue persists across restart ✓
- Operations synced after restart ✓

---

### Test 5: Real Airplane Mode Test (on device)

**Goal**: Test with real network isolation

**Steps on Real Device**:
```
1. Connect device to computer
2. flutter run
3. Enable airplane mode
4. App should show offline
5. Add products
6. Check pending count
7. Disable airplane mode
8. Wait 30 seconds
9. Operations should sync
10. Verify on server
```

**Expected Result**:
- Offline detection works ✓
- Operations queue ✓
- Auto-sync on reconnect ✓

---

## Quick Testing Commands

### Check Queue Stats
```dart
// In Flutter console or code
final stats = await queueService.getQueueStats();
print('Stats: $stats'); // {pending: 2, failed: 0}
```

### View Pending Operations
```dart
final pending = await queueService.getPendingOperations();
for (var op in pending) {
  print('${op.operationType} ${op.entityType}');
  print('Payload: ${op.payload}');
}
```

### View Failed Operations
```dart
final failed = await queueService.getFailedOperations();
for (var op in failed) {
  print('ID: ${op.id}');
  print('Error: ${op.errorMessage}');
  print('Retries: ${op.retryCount}');
}
```

### Manual Sync Trigger
```dart
// Via SyncProvider
await syncProvider.startSync();

// Check sync status
print('Is syncing: ${syncProvider.isSyncing}');
print('Message: ${syncProvider.syncMessage}');
```

### Simulate Offline Mode
```dart
// In your test code or main.dart
apiClient.setOnlineStatus(false);  // Force offline
apiClient.setOnlineStatus(true);   // Force online
```

---

## Testing Checklist

### Offline Operations
- [ ] Product can be added offline
- [ ] Sale can be recorded offline
- [ ] Expense can be added offline
- [ ] Operations show "will sync" message
- [ ] Pending count displays correctly
- [ ] No errors occur

### Sync Process
- [ ] Auto-sync triggers on reconnect
- [ ] Operations sent to server
- [ ] Queue marked as synced
- [ ] Sync count decreases
- [ ] No duplicate data

### Failure Handling
- [ ] Network error caught
- [ ] Operation queued as fallback
- [ ] Retry happens automatically
- [ ] Max retries enforced (5)
- [ ] Error message logged

### Persistence
- [ ] Queue survives app restart
- [ ] Operations re-synced after restart
- [ ] No data loss
- [ ] Database integrity maintained

### UI Integration
- [ ] Pending count visible
- [ ] Failed count visible
- [ ] Sync status shown
- [ ] Manual sync button works
- [ ] Status updates real-time

---

## Debug Output to Monitor

Watch console for:
```
✓ "Operation queued: product create"
✓ "Syncing 1 pending operations"
✓ "Synced operation: product create"
✓ "Queue stats: {pending: 0, failed: 0}"
✗ "Error syncing operation: [error message]"
```

---

## Testing with Backend

If testing with backend (optional):

```bash
# Terminal 1: Start backend
cd backend
npm run dev

# Terminal 2: Start Flutter
cd ..
flutter run

# Terminal 3: Monitor backend logs
cd backend
npm run dev  # Will show API calls
```

---

## What to Verify

After each test, verify:

1. **Local Queue** ✓
   - Check `/data/local/gouanzouh_queue.db` on device
   - Or view via SQLite browser

2. **Server Data** ✓
   - Login to backend API
   - Check if data exists
   - Timestamps should match local time

3. **App State** ✓
   - List shows all products (synced + cached)
   - No duplicates
   - Correct quantities/prices

---

## Common Issues & Fixes

**Issue**: Queue not syncing
- ✓ Check if `isOnline` is true
- ✓ Verify JWT token is set
- ✓ Check backend is running
- ✓ View logs: `print(syncProvider.syncMessage)`

**Issue**: Operations marked failed immediately
- ✓ Check error message: `op.errorMessage`
- ✓ Verify API endpoint format
- ✓ Check JWT token validity
- ✓ Verify server response

**Issue**: Queue grows without syncing
- ✓ Check connectivity service
- ✓ Verify connection detection stream
- ✓ Check if sync is manually triggered

**Issue**: App crashes
- ✓ Check database initialization
- ✓ Verify sqflite is installed
- ✓ Check migrations ran successfully
- ✓ View crash logs in Flutter console

---

## Performance Testing

### Sync Speed
```dart
final start = DateTime.now();
await syncProvider.startSync();
final elapsed = DateTime.now().difference(start);
print('Sync took: ${elapsed.inSeconds}s');
// Should be < 5 seconds per operation
```

### Queue Size
```dart
final stats = await queueService.getQueueStats();
print('Total pending: ${stats['pending']}');
// Test with 10, 50, 100 operations
// Should handle up to 1000+ without issues
```

### Memory Usage
- Monitor via Flutter DevTools
- Should use < 50MB for queue
- Database should be < 1MB per 1000 operations

---

## Success Criteria

✅ **Test Passed When**:
1. Operations queue successfully offline
2. Auto-sync triggers on reconnect
3. All data reaches backend
4. No duplicates created
5. Queue cleared after sync
6. Failed ops are recoverable
7. App survives restart with pending ops
8. UI shows correct status
9. No errors in console
10. Performance is acceptable

---

## Next Steps After Testing

If all tests pass:
1. ✅ Integration complete
2. ✅ Ready for deployment
3. ✅ Ready for production release

If issues found:
1. Check error messages
2. Review OFFLINE_SYNC_GUIDE.md
3. Check troubleshooting section
4. Verify dependencies installed
5. Review code in offline services

---

**Happy Testing! 🚀**

Run tests in order and report results. Each test should take 5-10 minutes.
