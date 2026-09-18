import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

class ArchitectureScreen extends StatelessWidget {
  const ArchitectureScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = AppTypography.textTheme;

    return Scaffold(
      backgroundColor: AppColors.cloudWhite,
      appBar: AppBar(title: const Text('System Architecture')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('RonaAir Architecture',
                  style: textTheme.headlineMedium),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Alur data dari kolam sampai ke keputusan pengguna.',
                style: textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.xl),

              _layer(
                title: '1. Kolam & Sensor',
                color: AppColors.aqua,
                items: [
                  'Permukaan air kolam (foto)',
                  'Kertas lakmus (foto pH)',
                  'ESP32 + sensor kualitas air',
                ],
              ),
              _arrow(),
              _layer(
                title: '2. Akuisisi',
                color: AppColors.deepWater,
                items: [
                  'Kamera smartphone',
                  'Image Quality Check',
                  'Pengiriman data sensor',
                ],
              ),
              _arrow(),
              _layer(
                title: '3. Analisis',
                color: AppColors.aqua,
                items: [
                  'Visual AI (MobileNetV3)',
                  'OpenCV + RonaCard calibration',
                  'MLR soft sensor (Estimated DO)',
                ],
              ),
              _arrow(),
              _layer(
                title: '4. Data Fusion & Risk Engine',
                color: AppColors.deepWater,
                items: [
                  'Gabungan evidence',
                  'Aturan + threshold',
                  'Temporal context',
                ],
              ),
              _arrow(),
              _layer(
                title: '5. Output',
                color: AppColors.aqua,
                items: [
                  'Risk status (NORMAL–DARURAT)',
                  'Explanation',
                  'Recommended action',
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.riskWaspadaBg,
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusLg),
                ),
                child: Text(
                  'RonaAir adalah sistem peringatan dini dan pendukung keputusan. '
                  'Bukan diagnosis spesies atau toksin. '
                  'Verifikasi lanjutan tetap memerlukan lab/rujukan.',
                  style: textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _layer({
    required String title,
    required Color color,
    required List<String> items,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration:
                    BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(title,
                  style: AppTypography.textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ...items.map(
            (i) => Padding(
              padding: const EdgeInsets.only(
                  left: 18, top: 4, bottom: 4),
              child: Text('• $i',
                  style: AppTypography.textTheme.bodySmall),
            ),
          ),
        ],
      ),
    );
  }

  Widget _arrow() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: Icon(Icons.arrow_downward,
            color: AppColors.midGray, size: 20),
      ),
    );
  }
}