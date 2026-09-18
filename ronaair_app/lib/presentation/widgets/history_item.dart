import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/risk_level.dart';
import 'risk_badge.dart';

class HistoryItem extends StatelessWidget {
  final RiskLevel risk;
  final DateTime date;
  final String summary;

  const HistoryItem({
    super.key,
    required this.risk,
    required this.date,
    required this.summary,
  });

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat('dd MMM • HH:mm', 'id_ID');

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.softGray),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: risk.backgroundColor,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Icon(Icons.water_drop,
                color: risk.color, size: 20),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RiskBadge(level: risk),
                const SizedBox(height: 6),
                Text(
                  formatter.format(date),
                  style: AppTypography.textTheme.bodySmall,
                ),
                Text(
                  summary,
                  style: AppTypography.textTheme.labelSmall,
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right,
              color: AppColors.midGray, size: 20),
        ],
      ),
    );
  }
}