import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

/// Baris kecil menampilkan status koneksi.
class ConnectionStatus extends StatelessWidget {
  final bool isOnline;
  final DateTime? lastUpdated;

  const ConnectionStatus({
    super.key,
    required this.isOnline,
    this.lastUpdated,
  });

  String _formatLastUpdated() {
    if (lastUpdated == null) return 'Belum ada data';
    final diff = DateTime.now().difference(lastUpdated!);
    if (diff.inSeconds < 60) return 'Diperbarui ${diff.inSeconds} detik lalu';
    if (diff.inMinutes < 60) return 'Diperbarui ${diff.inMinutes} menit lalu';
    if (diff.inHours < 24) return 'Diperbarui ${diff.inHours} jam lalu';
    return 'Diperbarui ${diff.inDays} hari lalu';
  }

  @override
  Widget build(BuildContext context) {
    final color =
        isOnline ? AppColors.statusOnline : AppColors.statusOffline;
    final text = isOnline ? 'Online' : 'Offline';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          '$text • ${_formatLastUpdated()}',
          style: AppTypography.textTheme.labelSmall,
        ),
      ],
    );
  }
}