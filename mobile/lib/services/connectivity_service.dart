import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

class ConnectivityService extends ChangeNotifier {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<ConnectivityResult> _connectivitySubscription;
  
  ConnectivityResult _connectionStatus = ConnectivityResult.none;
  bool get isConnected => _connectionStatus != ConnectivityResult.none;
  bool get isWifi => _connectionStatus == ConnectivityResult.wifi;
  bool get isMobile => _connectionStatus == ConnectivityResult.mobile;

  ConnectivityResult get connectionStatus => _connectionStatus;

  Future<void> initialize() async {
    try {
      _connectionStatus = await _connectivity.checkConnectivity();
      _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
        _updateConnectionStatus,
        onError: (error) {
          debugPrint('Connectivity error: $error');
        },
      );
    } catch (e) {
      debugPrint('Failed to initialize connectivity service: $e');
    }
  }

  void _updateConnectionStatus(ConnectivityResult result) {
    _connectionStatus = result;
    notifyListeners();
    
    if (kDebugMode) {
      debugPrint('Connectivity changed: $result');
    }
  }

  Future<bool> hasInternetConnection() async {
    try {
      final result = await _connectivity.checkConnectivity();
      return result != ConnectivityResult.none;
    } catch (e) {
      debugPrint('Error checking internet connection: $e');
      return false;
    }
  }

  void dispose() {
    _connectivitySubscription.cancel();
    super.dispose();
  }
}