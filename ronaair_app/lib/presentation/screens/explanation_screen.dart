import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/risk_level.dart';
import '../../mock/mock_data.dart';

class ExplanationScreen extends StatelessWidget {
  const ExplanationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = AppTypography.textTheme;
    final risk = MockData.currentRisk;

    final factors = [
      ('Analisis Visual', 0.6, 'Perubahan warna ringan'),
      ('pH', 0.4, 'Sedikit di bawah normal'),
      ('Suhu', 0.2, 'Dalam rentang normal'),
      ('Turbidity', 0.7, 'Di atas normal'),
      ('Estimated DO', 0.5, 'Perlu perhatian'),
    ];

    return Scaffold(
      backgroundColor: AppColors.cloudWhite,
      appBar: AppBar(title: const Text('Mengapa hasilnya?')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Mengapa ${risk.label}?',
                style: textTheme.headlineMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Hasil ini berasal dari gabungan beberapa indikator, '
                'bukan dari satu parameter saja.',
                style: textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.xl),

              ...factors.map((f) {
                final (label, score, desc) = f;
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(label, style: textTheme.titleMedium),
                          Text(
                            '${(score * 100).toInt()}%',
                            style: textTheme.bodySmall,
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: score,
                          minHeight: 8,
                          backgroundColor: AppColors.softGray,
                          valueColor: AlwaysStoppedAnimation(
                            score > 0.6 ? risk.color : AppColors.aqua,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(desc, style: textTheme.bodySmall),
                    ],
                  ),
                );
              }),

              const SizedBox(height: AppSpacing.xl),
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.riskWaspadaBg,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  border: Border.all(
                    color: AppColors.riskWaspada.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: AppColors.riskWaspada,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        'Hasil ini adalah indikasi risiko, bukan diagnosis. '
                        'Untuk verifikasi lebih lanjut, diperlukan pemeriksaan '
                        'kualitas air atau uji laboratorium.',
                        style: textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}