import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  final Connectivity _connectivity = Connectivity();
  bool _isOnline = true;

  bool get isOnline => _isOnline;

  Future<void> initialize() async {
    final result = await _connectivity.checkConnectivity();
    _isOnline = result != ConnectivityResult.none;
  }

  Stream<bool> get connectionStatus {
    return _connectivity.onConnectivityChanged
        .map((result) => result != ConnectivityResult.none);
  }

  void dispose() {
    // Cleanup if needed
  }
}
