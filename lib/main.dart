import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
import 'providers/auth_provider.dart';
import 'providers/stock_provider.dart';
import 'providers/report_provider.dart';
import 'providers/expense_provider.dart';
import 'providers/locale_provider.dart';
import 'providers/sync_provider.dart';
import 'services/connectivity_service.dart';
import 'services/offline_queue_service.dart';
import 'services/sync_service.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/product_list_screen.dart';
import 'screens/sales_history_screen.dart';
import 'screens/report_screen.dart';
import 'screens/admin_dashboard_screen.dart';
import 'screens/record_sale_screen.dart';
import 'screens/expense_list_screen.dart';
import 'screens/settings_screen.dart';
import 'models/user.dart';
import 'utils/app_colors.dart';
import 'utils/notification_service.dart';
import 'utils/api_config.dart';

final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  bool apiReady = false;
  String? initError;

  try {
    final res = await http.get(Uri.parse('$API_BASE_URL/health')).timeout(const Duration(seconds: 5));
    if (res.statusCode == 200) {
      apiReady = true;
    } else {
      initError = 'API unhealthy: ${res.statusCode}';
    }
  } catch (e) {
    initError = e.toString();
  }

  await NotificationService.init();

  final queueService = OfflineQueueService();
  final apiClient = ApiClient();
  final syncService = SyncService(queueService, apiClient);
  final connectivityService = ConnectivityService();
  await connectivityService.initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => StockProvider()),
        ChangeNotifierProvider(create: (_) => ReportProvider()),
        ChangeNotifierProvider(create: (_) => ExpenseProvider()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
        ChangeNotifierProvider(create: (_) => SyncProvider(syncService)),
        Provider.value(value: connectivityService),
      ],
      child: SalesApp(apiReady: apiReady, initError: initError),
    ),
  );
}

class SalesApp extends StatelessWidget {
  final bool apiReady;
  final String? initError;

  const SalesApp({super.key, required this.apiReady, this.initError});

  @override
  Widget build(BuildContext context) {
    final localeProvider = context.watch<LocaleProvider>();

    return MaterialApp(
      scaffoldMessengerKey: scaffoldMessengerKey,
      title: 'DigitalShop',
      debugShowCheckedModeBanner: false,
      locale: localeProvider.locale,
      localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('sw'),
      ],
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.martiamGreen,
          primary: AppColors.martiamGreen,
          secondary: AppColors.darkGreen,
          surface: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.martiamGreen,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: Colors.white,
          indicatorColor: AppColors.martiamGreen.withValues(alpha: 0.1),
          labelTextStyle: WidgetStateProperty.all(
            const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.darkGreen),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.martiamGreen,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            textStyle: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.martiamGreen, width: 2),
          ),
          filled: true,
          fillColor: Colors.grey.shade50,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          clipBehavior: Clip.antiAlias,
        ),
      ),
      home: !apiReady 
        ? Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 60),
                    const SizedBox(height: 20),
                    const Text('Backend API Unreachable', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    const SizedBox(height: 10),
                    Text(initError ?? 'Unknown error. Check network or API configuration.', textAlign: TextAlign.center),
                    const SizedBox(height: 30),
                    ElevatedButton(onPressed: () => exit(0), child: const Text('RESTART APP')),
                  ],
                ),
              ),
            ),
          )
        : Consumer<AuthProvider>(
            builder: (context, auth, _) {
              if (auth.currentUser == null) {
                return const LoginScreen();
              }
              if (auth.currentUser!.role == UserRole.admin) {
                return const AdminDashboardScreen();
              }
              return const AppShell();
            },
          ),
    );
  }
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;
  late final StreamSubscription<bool> _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      if (auth.currentUser != null) {
        context.read<StockProvider>().listenToData();
        context.read<ExpenseProvider>().listenToData();
      }

      // Initial Sync Status
      context.read<SyncProvider>().refreshQueueStats();

      // Setup Connectivity Listener
      final connectivity = context.read<ConnectivityService>();
      _connectivitySubscription = connectivity.connectionStatus.listen((isOnline) {
        ApiClient.setOnline(isOnline);
        if (isOnline) {
          _handleReturnOnline();
        }
      });
    });
  }

  void _handleReturnOnline() async {
    final syncProvider = context.read<SyncProvider>();
    await syncProvider.refreshQueueStats();
    
    if (syncProvider.hasPendingOperations) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Internet Restored. Seeding data to cloud...'),
            backgroundColor: Colors.blue,
          ),
        );
      }
      await syncProvider.startSync();
      
      // Refresh data after sync
      if (mounted) {
        context.read<StockProvider>().listenToData();
        context.read<ExpenseProvider>().listenToData();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Data seeded successfully.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    super.dispose();
  }

  static const List<Widget> _screens = [
    DashboardScreen(),
    ProductListScreen(),
    ExpenseListScreen(),
    SalesHistoryScreen(),
    ReportScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedIndex == 0 ? l10n.dashboard.toUpperCase() : 
                    _selectedIndex == 1 ? l10n.stock.toUpperCase() :
                    _selectedIndex == 2 ? l10n.expenses.toUpperCase() :
                    _selectedIndex == 3 ? l10n.sales.toUpperCase() :
                    l10n.finance.toUpperCase()),
        actions: [
          Consumer2<StockProvider, ExpenseProvider>(
            builder: (context, stock, expense, _) {
              if (!stock.isOnline) {
                return const Padding(
                  padding: EdgeInsets.only(right: 8.0),
                  child: Tooltip(
                    message: 'Offline - Check connection',
                    child: Icon(Icons.cloud_off, color: Colors.orange, size: 20),
                  ),
                );
              }
              if (stock.isSyncing || expense.isSyncing) {
                return const Padding(
                  padding: EdgeInsets.only(right: 8.0),
                  child: Tooltip(
                    message: 'Syncing with server...',
                    child: Icon(Icons.sync, color: Colors.white, size: 20),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.cloud_upload),
            tooltip: 'Publish to Cloud',
            onPressed: () async {
              final stock = context.read<StockProvider>();
              final expense = context.read<ExpenseProvider>();

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Publishing data to cloud...'), duration: Duration(seconds: 1)),
              );

              try {
                // Wait for all pending writes to be acknowledged by the server
                await Future.wait([
                  stock.syncWithServer(),
                  expense.syncWithServer(),
                ]).timeout(const Duration(seconds: 15));

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Successfully Published to Cloud!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Publish timed out. Check your internet connection.'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) => setState(() => _selectedIndex = index),
        destinations: [
          NavigationDestination(icon: const Icon(Icons.dashboard_outlined), selectedIcon: const Icon(Icons.dashboard, color: AppColors.martiamGreen), label: l10n.dashboard),
          NavigationDestination(icon: const Icon(Icons.inventory_2_outlined), selectedIcon: const Icon(Icons.inventory_2, color: AppColors.martiamGreen), label: l10n.stock),
          NavigationDestination(icon: const Icon(Icons.payments_outlined), selectedIcon: const Icon(Icons.payments, color: Colors.red), label: l10n.expenses),
          NavigationDestination(icon: const Icon(Icons.receipt_long_outlined), selectedIcon: const Icon(Icons.receipt_long, color: AppColors.martiamGreen), label: l10n.sales),
          NavigationDestination(icon: const Icon(Icons.bar_chart_outlined), selectedIcon: const Icon(Icons.bar_chart, color: AppColors.martiamGreen), label: l10n.finance),
        ],
      ),
      floatingActionButton: _selectedIndex != 0 ? null : FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RecordSaleScreen())),
        backgroundColor: AppColors.darkGreen,
        icon: const Icon(Icons.add_shopping_cart, color: Colors.white),
        label: Text(l10n.newSale, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
