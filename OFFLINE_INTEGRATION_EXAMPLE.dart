// Example: How to integrate offline support into main.dart
// 
// This shows the key integration points for offline/sync functionality

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'api_client.dart';
import 'services/offline_queue_service.dart';
import 'services/sync_service.dart';
import 'services/connectivity_service.dart';
import 'providers/sync_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late ConnectivityService _connectivityService;
  late OfflineQueueService _queueService;
  late ApiClient _apiClient;
  late SyncService _syncService;
  late SyncProvider _syncProvider;

  @override
  void initState() {
    super.initState();
    _initializeOfflineServices();
  }

  Future<void> _initializeOfflineServices() async {
    // Initialize connectivity service
    _connectivityService = ConnectivityService();
    await _connectivityService.initialize();

    // Initialize offline queue
    _queueService = OfflineQueueService();

    // Initialize API client with queue
    _apiClient = ApiClient(queueService: _queueService);

    // Initialize sync service
    _syncService = SyncService(_queueService, _apiClient);

    // Initialize sync provider for UI
    _syncProvider = SyncProvider(_syncService);

    // Listen for connection changes
    _connectivityService.connectionStatus.listen((isOnline) {
      if (isOnline) {
        _apiClient.setOnlineStatus(true);
        // Auto-sync when connection restored
        _syncProvider.startSync();
      } else {
        _apiClient.setOnlineStatus(false);
      }
    });

    // Periodic sync attempt (every 30 seconds when online)
    Future.doWhile(() async {
      await Future.delayed(Duration(seconds: 30));
      if (_connectivityService._isOnline && !_syncProvider.isSyncing) {
        await _syncProvider.startSync();
      }
      return true; // Keep looping
    });
  }

  @override
  void dispose() {
    _queueService.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Sync provider for UI
        ChangeNotifierProvider.value(value: _syncProvider),
        // Other providers...
      ],
      child: MaterialApp(
        title: 'Gouanzouh',
        theme: ThemeData(primarySwatch: Colors.green),
        home: Scaffold(
          appBar: AppBar(
            title: const Text('Gouanzouh'),
            actions: [
              // Sync status indicator
              Consumer<SyncProvider>(
                builder: (context, syncProvider, _) {
                  if (syncProvider.isSyncing) {
                    return Padding(
                      padding: EdgeInsets.all(16),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      ),
                    );
                  }

                  if (syncProvider.hasPendingOperations) {
                    return Padding(
                      padding: EdgeInsets.all(8),
                      child: Chip(
                        label: Text('${syncProvider.pendingCount} pending'),
                        avatar: Icon(Icons.cloud_upload, size: 18),
                      ),
                    );
                  }

                  if (syncProvider.hasFailedOperations) {
                    return Padding(
                      padding: EdgeInsets.all(8),
                      child: Chip(
                        label: Text('${syncProvider.failedCount} failed'),
                        avatar: Icon(Icons.error, size: 18),
                        backgroundColor: Colors.red.shade100,
                      ),
                    );
                  }

                  return SizedBox.shrink();
                },
              ),
            ],
          ),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Connectivity status
                Consumer<SyncProvider>(
                  builder: (context, syncProvider, _) {
                    final isOnline = _connectivityService._isOnline;
                    return Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Text(
                              isOnline ? '🟢 Online' : '🔴 Offline',
                              style: TextStyle(fontSize: 18),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Pending: ${syncProvider.pendingCount} | '
                              'Failed: ${syncProvider.failedCount}',
                            ),
                            SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: syncProvider.isSyncing
                                  ? null
                                  : () => syncProvider.startSync(),
                              child: Text('Sync Now'),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
