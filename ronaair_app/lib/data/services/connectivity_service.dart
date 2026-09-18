import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Service yang memantau status koneksi (online/offline).
/// Semua bagian aplikasi bisa "dengar" perubahan status.
class ConnectivityService extends ChangeNotifier {
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _sub;

  bool _isOnline = true;

  bool get isOnline => _isOnline;

  ConnectivityService() {
    _init();
  }

  Future<void> _init() async {
    // Cek status awal
    final results = await _connectivity.checkConnectivity();
    _updateFromResults(results);

    // Pantau perubahan
    _sub = _connectivity.onConnectivityChanged.listen(_updateFromResults);
  }

  void _updateFromResults(List<ConnectivityResult> results) {
    final online = results.any(
      (r) => r == ConnectivityResult.wifi ||
             r == ConnectivityResult.mobile ||
             r == ConnectivityResult.ethernet,
    );

    if (online != _isOnline) {
      _isOnline = online;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}