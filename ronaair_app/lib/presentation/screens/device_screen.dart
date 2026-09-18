import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

class DeviceScreen extends StatelessWidget {
  const DeviceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = AppTypography.textTheme;

    final devices = [
      ('ESP32', Icons.memory, true),
      ('Sensor Suhu (DS18B20)', Icons.thermostat, true),
      ('Sensor pH', Icons.science_outlined, true),
      ('Sensor Turbidity', Icons.water_drop_outlined, true),
      ('Koneksi Internet', Icons.wifi, true),
    ];

    return Scaffold(
      backgroundColor: AppColors.cloudWhite,
      appBar: AppBar(title: const Text('Status Perangkat')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.riskNormalBg,
                borderRadius:
                    BorderRadius.circular(AppSpacing.radiusLg),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle,
                      color: AppColors.statusOnline),
                  const SizedBox(width: AppSpacing.md),
                  Text('Semua perangkat terhubung',
                      style: textTheme.titleMedium),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            ...devices.map((d) {
              final (name, icon, ok) = d;
              return Padding(
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
                    children: [
                      Icon(icon, color: AppColors.aqua, size: 22),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Text(name,
                            style: textTheme.bodyMedium),
                      ),
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: ok
                              ? AppColors.statusOnline
                              : AppColors.statusOffline,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        ok ? 'Aktif' : 'Off',
                        style: textTheme.labelSmall,
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}