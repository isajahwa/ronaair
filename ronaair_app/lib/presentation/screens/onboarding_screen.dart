import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import 'dashboard_screen.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = AppTypography.textTheme;

    return Scaffold(
      backgroundColor: AppColors.cloudWhite,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),

              // Logo
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: AppColors.aqua,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                ),
                child: const Icon(
                  Icons.water_drop,
                  color: Colors.white,
                  size: 44,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Nama
              Text('RonaAir', style: textTheme.displayLarge),
              const SizedBox(height: AppSpacing.sm),

              // Tagline
              Text(
                'Sistem Peringatan Dini\nKualitas Air Kolam Ikan',
                style: textTheme.headlineMedium?.copyWith(
                  color: AppColors.deepWater,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Deskripsi
              Text(
                'Bantu kenali perubahan kondisi kolam lebih awal. '
                'Ambil foto, baca sensor, dapatkan status risiko dan rekomendasi tindakan.',
                style: textTheme.bodyMedium,
              ),

              const Spacer(),

              // Tombol Mulai
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (_) => const DashboardScreen(),
                    ),
                  );
                },
                child: const Text('Mulai'),
              ),
              const SizedBox(height: AppSpacing.md),
              Center(
                child: Text(
                  AppConstants.appName,
                  style: textTheme.labelSmall,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}