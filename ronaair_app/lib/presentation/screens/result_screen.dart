import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/risk_level.dart';
import '../../mock/mock_data.dart';
import '../widgets/risk_badge.dart';
import 'explanation_screen.dart';
import 'recommendation_screen.dart';

class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = AppTypography.textTheme;
    final risk = MockData.currentRisk;

    return Scaffold(
      backgroundColor: AppColors.cloudWhite,
      appBar: AppBar(
        title: const Text('Hasil Pemeriksaan'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () =>
              Navigator.of(context).popUntil((r) => r.isFirst),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Big card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.xl),
                decoration: BoxDecoration(
                  color: risk.backgroundColor,
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusXl),
                  border: Border.all(
                    color: risk.color.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Risk Level', style: textTheme.bodySmall),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      risk.label,
                      style: textTheme.displayLarge?.copyWith(
                        color: risk.color,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(risk.description,
                        style: textTheme.bodyMedium),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              Text('Faktor Kontribusi',
                  style: textTheme.titleMedium),
              const SizedBox(height: AppSpacing.md),

              ...MockData.currentFactors.map(
                (f) => Padding(
                  padding:
                      const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(
                          AppSpacing.radiusMd),
                      border:
                          Border.all(color: AppColors.softGray),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 18,
                          color: risk.color,
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Text(f,
                              style: textTheme.bodyMedium),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Visual indicator
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusLg),
                  border: Border.all(color: AppColors.softGray),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.auto_awesome,
                        color: AppColors.aqua),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Visual condition',
                              style: textTheme.bodySmall),
                          Text('Perubahan ringan terdeteksi',
                              style: textTheme.titleMedium),
                        ],
                      ),
                    ),
                    RiskBadge(level: risk),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),

              // Tombol navigasi
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  side: const BorderSide(color: AppColors.aqua),
                  foregroundColor: AppColors.aqua,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                        AppSpacing.radiusMd),
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const ExplanationScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.help_outline),
                label: const Text('Mengapa hasilnya?'),
              ),
              const SizedBox(height: AppSpacing.md),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const RecommendationScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Lihat Rekomendasi'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}