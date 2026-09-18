import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/services/connectivity_service.dart';
import '../providers/dashboard_provider.dart';
import '../providers/history_provider.dart';

/// Widget yang otomatis refresh data saat koneksi pulih.
class AutoRetryWrapper extends StatefulWidget {
  final Widget child;

  const AutoRetryWrapper({super.key, required this.child});

  @override
  State<AutoRetryWrapper> createState() => _AutoRetryWrapperState();
}

class _AutoRetryWrapperState extends State<AutoRetryWrapper> {
  bool _wasOnline = true;

  @override
  Widget build(BuildContext context) {
    return Consumer<ConnectivityService>(
      builder: (context, conn, child) {
        // Deteksi perubahan dari offline → online
        if (conn.isOnline && !_wasOnline) {
          // Auto-refresh semua provider
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            context.read<DashboardProvider>().refresh();
            context.read<HistoryProvider>().refresh();
          });
        }
        _wasOnline = conn.isOnline;

        return widget.child;
      },
    );
  }
}