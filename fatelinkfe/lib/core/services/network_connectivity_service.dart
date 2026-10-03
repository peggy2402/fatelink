import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Dịch vụ giám sát trạng thái kết nối mạng toàn cục
class NetworkConnectivityService {
  NetworkConnectivityService._internal();
  static final NetworkConnectivityService instance = NetworkConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  final ValueNotifier<bool> isOnlineNotifier = ValueNotifier<bool>(true);
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  bool get isOnline => isOnlineNotifier.value;

  Future<void> initialize() async {
    await checkConnection();

    _subscription = _connectivity.onConnectivityChanged.listen((results) async {
      await _handleConnectivityChange(results);
    });
  }

  Future<void> _handleConnectivityChange(List<ConnectivityResult> results) async {
    final bool hasInterface = results.any((r) => r != ConnectivityResult.none);
    if (!hasInterface) {
      _updateStatus(false);
      return;
    }

    final hasRealInternet = await _hasRealInternet();
    _updateStatus(hasRealInternet);
  }

  Future<bool> checkConnection() async {
    try {
      final results = await _connectivity.checkConnectivity();
      final bool hasInterface = results.any((r) => r != ConnectivityResult.none);
      if (!hasInterface) {
        _updateStatus(false);
        return false;
      }
      final hasRealInternet = await _hasRealInternet();
      _updateStatus(hasRealInternet);
      return hasRealInternet;
    } catch (_) {
      _updateStatus(false);
      return false;
    }
  }

  Future<bool> _hasRealInternet() async {
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 3));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  void _updateStatus(bool online) {
    if (isOnlineNotifier.value != online) {
      isOnlineNotifier.value = online;
    }
  }

  void dispose() {
    _subscription?.cancel();
  }
}
