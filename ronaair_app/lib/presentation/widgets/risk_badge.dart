import 'package:flutter/material.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/risk_level.dart';

/// Badge kecil menampilkan status risiko.
class RiskBadge extends StatelessWidget {
  final RiskLevel level;
  final bool large;

  const RiskBadge({
    super.key,
    required this.level,
    this.large = false,
  });

  @override
  Widget build(BuildContext context) {
    final fontSize = large ? 16.0 : 12.0;
    final paddingV = large ? 10.0 : 6.0;
    final paddingH = large ? 16.0 : 12.0;

    return Container(
      padding: EdgeInsets.symmetric(
        vertical: paddingV,
        horizontal: paddingH,
      ),
      decoration: BoxDecoration(
        color: level.backgroundColor,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(color: level.color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: large ? 10 : 8,
            height: large ? 10 : 8,
            decoration: BoxDecoration(
              color: level.color,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: AppSpacing.sm),
          Text(
            level.label,
            style: AppTypography.textTheme.labelMedium?.copyWith(
              color: level.color,
              fontWeight: FontWeight.w700,
              fontSize: fontSize,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}