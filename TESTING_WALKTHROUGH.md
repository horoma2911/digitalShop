# 🚀 QUICK TESTING WALKTHROUGH

## Step 1: Start the App (2 minutes)

```bash
cd C:\Users\VICTUS\Pictures\gouanzouh
flutter run
```

Wait for app to load. You should see the Gouanzouh home screen.

---

## Step 2: Test Basic Offline (3 minutes)

### 2.1 Open Flutter DevTools
- In terminal where app is running, press `d`
- This opens DevTools in browser

### 2.2 Simulate Offline Mode
In your app's code, temporarily add this to `main.dart` in `initState`:

```dart
// Temporary test - remove after testing!
Future.delayed(Duration(seconds: 2), () {
  _apiClient.setOnlineStatus(false);
  print('🔴 OFFLINE MODE ACTIVATED');
});
```

**Or manually via console in DevTools**:
```dart
apiClient.setOnlineStatus(false);
print('Status: Offline')
```

### 2.3 Add Product While Offline
1. In the app, go to "Add Product" screen
2. Fill in:
   - Name: "Test Offline Product"
   - Quantity: 5
   - Cost: 100
   - Selling: 150
3. Tap "Add Product"
4. **You should see**: "✓ Added (will sync)"

### 2.4 Check Queue Stats
```dart
// In DevTools console or your test code
final stats = await queueService.getQueueStats();
print('Queue: ${stats}');  // Should show {pending: 1, failed: 0}
```

✅ **Test Passed if**: 
- Product appears in local list
- Message says "will sync"
- Queue shows 1 pending

---

## Step 3: Go Online & Auto-Sync (2 minutes)

### 3.1 Restore Connection
In DevTools console:
```dart
apiClient.setOnlineStatus(true);
print('Status: Online')
```

### 3.2 Trigger Sync (or wait 30 seconds for auto-sync)
```dart
await syncProvider.startSync();
print('Syncing...')
```

### 3.3 Watch Status Updates
- Pending count should decrease
- Status should show "✓ All synced"
- Product stays in local list

### 3.4 Verify Queue Empty
```dart
final stats = await queueService.getQueueStats();
print('Queue: ${stats}');  // Should show {pending: 0, failed: 0}
```

✅ **Test Passed if**:
- Queue synced successfully
- Pending count is 0
- No errors in console

---

## Step 4: Test Data Persistence (5 minutes)

### 4.1 Add Another Product Offline
```dart
apiClient.setOnlineStatus(false);
```

1. Add product: "Test Persistence"
2. Check queue: should have 1 pending

### 4.2 Close App Completely
- Close Flutter app (Ctrl+C in terminal)
- Wait 2 seconds

### 4.3 Reopen App
```bash
flutter run
```

### 4.4 Verify Queue Persists
```dart
final stats = await queueService.getQueueStats();
print('Queue after restart: ${stats}');  // Should still show {pending: 1, failed: 0}
```

### 4.5 Go Online & Sync
```dart
apiClient.setOnlineStatus(true);
await syncProvider.startSync();
```

✅ **Test Passed if**:
- Queue persisted after restart
- Operation synced successfully
- Data appears on backend

---

## Step 5: Test Failed Operations (3 minutes)

### 5.1 Go Offline
```dart
apiClient.setOnlineStatus(false);
```

### 5.2 Add Invalid Product
(Try adding with missing/invalid data that server will reject)

```dart
await apiClient.addProduct({
  'name': '',  // Invalid: empty name
  'quantity': -5,  // Invalid: negative qty
  'cost_price': 100,
  'selling_price': 150
});
```

### 5.3 Go Online & Sync
```dart
apiClient.setOnlineStatus(true);
await syncProvider.startSync();
```

### 5.4 Check Failed Operations
```dart
final failed = await queueService.getFailedOperations();
for (var op in failed) {
  print('Failed: ${op.errorMessage}');
}
```

### 5.5 Manual Retry
```dart
if (failed.isNotEmpty) {
  await syncProvider.retryFailedOperation(failed[0].id!);
}
```

✅ **Test Passed if**:
- Operation marked as failed
- Error message shows
- Manual retry works (or shows validation error)

---

## Complete Test Checklist

Run through all tests:

- [ ] **Test 1**: Add product offline → shows "will sync" ✓
- [ ] **Test 2**: Check queue shows 1 pending ✓
- [ ] **Test 3**: Go online → auto-sync triggers ✓
- [ ] **Test 4**: Queue shows 0 pending after sync ✓
- [ ] **Test 5**: Add product while offline ✓
- [ ] **Test 6**: Close app & reopen ✓
- [ ] **Test 7**: Queue still shows pending ✓
- [ ] **Test 8**: Sync after restart works ✓
- [ ] **Test 9**: Add invalid product offline ✓
- [ ] **Test 10**: Marked as failed on sync ✓
- [ ] **Test 11**: Manual retry works ✓

---

## Console Commands for Testing

Keep these handy:

```dart
// Check online status
print('Online: ${apiClient._isOnline}');

// Force offline
apiClient.setOnlineStatus(false);

// Force online
apiClient.setOnlineStatus(true);

// Check queue stats
final stats = await queueService.getQueueStats();
print('Queue: ${stats}');

// View all pending
final pending = await queueService.getPendingOperations();
pending.forEach((op) => print('${op.operationType} ${op.entityType}'));

// View all failed
final failed = await queueService.getFailedOperations();
failed.forEach((op) => print('${op.id}: ${op.errorMessage}'));

// Manually sync
await syncProvider.startSync();

// Clear synced
await queueService.clearSynced();
```

---

## What to Look For in Logs

### Success Logs ✓
```
🟢 Operation queued: create product
🟢 Syncing 1 pending operations
🟢 POST /products successful
🟢 Synced operation: create product
🟢 Queue now empty
```

### Error Logs ✗
```
🔴 Cannot add to queue: null error
🔴 Sync failed: connection error
🔴 API returned 400: validation error
```

---

## Troubleshooting

**Queue not showing pending after offline operation?**
- ✓ Check if `setOnlineStatus(false)` worked
- ✓ Verify queueService is initialized
- ✓ Check console for errors

**Sync not triggering on connect?**
- ✓ Check if `setOnlineStatus(true)` called
- ✓ Verify syncProvider exists
- ✓ Check if isSyncing is still true

**Queue showing but not syncing?**
- ✓ Check backend is running
- ✓ Verify JWT token is valid
- ✓ Check error message: `syncProvider.syncMessage`

**Data not appearing on backend?**
- ✓ Check backend logs
- ✓ Verify API endpoint format
- ✓ Check database connection

---

## Success Indicators

✅ **Your offline support is working when**:

1. Operations queue when offline
2. Queue persists after app restart
3. Auto-sync triggers on reconnect
4. No duplicate data on backend
5. Queue clears after successful sync
6. Failed operations are retryable
7. Error messages are logged
8. UI updates show correct status
9. No crashes occur
10. Performance is acceptable (< 5s per operation)

---

## Next Steps After Testing

✅ **All tests pass?**
1. Update main.dart with permanent offline initialization
2. Add UI widgets for sync status (optional)
3. Deploy to real devices
4. Test on production backend

❌ **Tests fail?**
1. Check error messages
2. Review OFFLINE_SYNC_GUIDE.md
3. Verify all services initialized
4. Check dependencies installed

---

## Expected Test Time

- Quick test (Steps 1-3): ~10 minutes
- Full test (Steps 1-5): ~20 minutes
- With real device: ~30 minutes

**Start testing now! 🚀**
