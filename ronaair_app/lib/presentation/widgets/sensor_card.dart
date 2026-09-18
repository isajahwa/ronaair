import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

/// Card untuk satu parameter sensor.
class SensorCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String unit;
  final String? status;
  final Color? statusColor;

  const SensorCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
    this.status,
    this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = AppTypography.textTheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.softGray),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.aqua),
              const SizedBox(width: AppSpacing.sm),
              Text(
                label,
                style: textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          RichText(
            text: TextSpan(
              style: textTheme.headlineMedium,
              children: [
                TextSpan(text: value),
                TextSpan(
                  text: ' $unit',
                  style: textTheme.bodySmall,
                ),
              ],
            ),
          ),
          if (status != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              status!,
              style: textTheme.labelSmall?.copyWith(
                color: statusColor ?? AppColors.midGray,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}