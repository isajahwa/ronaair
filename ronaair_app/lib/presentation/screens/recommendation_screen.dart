import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/risk_level.dart';
import '../../mock/mock_data.dart';

class RecommendationScreen extends StatelessWidget {
  const RecommendationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = AppTypography.textTheme;
    final risk = MockData.currentRisk;

    return Scaffold(
      backgroundColor: AppColors.cloudWhite,
      appBar: AppBar(title: const Text('Rekomendasi Tindakan')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Untuk status ${risk.label}',
                style: textTheme.headlineMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Rekomendasi ini bersifat preventif dan aman, '
                'bukan diagnosis atau instruksi medis.',
                style: textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.xl),

              ...MockData.currentRecommendations.asMap().entries.map(
                    (e) => Padding(
                      padding:
                          const EdgeInsets.only(bottom: AppSpacing.md),
                      child: Container(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(
                              AppSpacing.radiusLg),
                          border:
                              Border.all(color: AppColors.softGray),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: AppColors.aqua
                                    .withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  '${e.key + 1}',
                                  style: textTheme.labelMedium
                                      ?.copyWith(
                                    color: AppColors.aqua,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Text(
                                e.value,
                                style: textTheme.bodyMedium,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

              const Spacer(),

              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.riskDaruratBg,
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusLg),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.warning_amber,
                      color: AppColors.riskDarurat,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        'Jangan mengambil keputusan besar hanya berdasarkan aplikasi. '
                        'Konsultasikan dengan penyuluh untuk kondisi serius.',
                        style: textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).popUntil((r) => r.isFirst);
                },
                child: const Text('Selesai'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}