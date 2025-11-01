import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  final Connectivity _connectivity = Connectivity();

  factory ConnectivityService() {
    return _instance;
  }

  ConnectivityService._internal();

  // Check if internet connection is available
  Future<bool> isConnected() async {
    try {
      final result = await _connectivity.checkConnectivity();
      return result != ConnectivityResult.none;
    } catch (e) {
      debugPrint('Failed to check connectivity: $e');
      return false;
    }
  }

  // Stream of connectivity changes
  Stream<ConnectivityResult> get connectivityStream => _connectivity.onConnectivityChanged;

  // Listen for connectivity changes
  void setupConnectivityListener(Function(bool) onConnectivityChanged) {
    _connectivity.onConnectivityChanged.listen((ConnectivityResult result) {
      onConnectivityChanged(result != ConnectivityResult.none);
    });
  }
}