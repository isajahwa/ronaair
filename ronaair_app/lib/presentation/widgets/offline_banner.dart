import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../data/services/connectivity_service.dart';

/// Banner global yang muncul saat offline.
/// Pasang di wrapper MaterialApp agar muncul di semua screen.
class OfflineBanner extends StatelessWidget {
  final Widget child;

  const OfflineBanner({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Consumer<ConnectivityService>(
      builder: (context, conn, _) {
        return Stack(
          children: [
            // Konten utama
            child,

            // Banner di atas layar saat offline
            if (!conn.isOnline)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Material(
                  color: AppColors.riskWaspadaBg,
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.cloud_off,
                            size: 16,
                            color: AppColors.riskWaspada,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Offline — data mungkin tidak terbaru',
                              style: AppTypography.textTheme.labelSmall
                                  ?.copyWith(
                                color: AppColors.riskWaspada,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}