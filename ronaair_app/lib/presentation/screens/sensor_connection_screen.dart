import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../mock/mock_data.dart';
import '../widgets/sensor_card.dart';
import 'data_fusion_screen.dart';

class SensorConnectionScreen extends StatelessWidget {
  const SensorConnectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = AppTypography.textTheme;
    final sensor = MockData.currentSensor;

    return Scaffold(
      backgroundColor: AppColors.cloudWhite,
      appBar: AppBar(title: const Text('Data Sensor')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status device
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.riskNormalBg,
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusLg),
                  border: Border.all(
                      color: AppColors.statusOnline.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.sensors,
                        color: AppColors.statusOnline),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('ESP32 Terhubung',
                              style: textTheme.titleMedium),
                          Text(
                            'Diperbarui baru saja',
                            style: textTheme.labelSmall,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.refresh,
                          color: AppColors.statusOnline),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              Text('Nilai Sensor', style: textTheme.titleMedium),
              const SizedBox(height: AppSpacing.md),

              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: AppSpacing.md,
                crossAxisSpacing: AppSpacing.md,
                childAspectRatio: 1.35,
                children: [
                  SensorCard(
                    icon: Icons.thermostat,
                    label: 'Suhu',
                    value: sensor.temperature.toStringAsFixed(1),
                    unit: '°C',
                  ),
                  SensorCard(
                    icon: Icons.science_outlined,
                    label: 'pH',
                    value: sensor.ph.toStringAsFixed(1),
                    unit: '',
                  ),
                  SensorCard(
                    icon: Icons.water_drop_outlined,
                    label: 'Turbidity',
                    value: sensor.turbidity.toStringAsFixed(1),
                    unit: 'NTU',
                  ),
                  SensorCard(
                    icon: Icons.bubble_chart_outlined,
                    label: 'Est. DO',
                    value: sensor.estimatedDo.toStringAsFixed(1),
                    unit: 'mg/L',
                  ),
                ],
              ),

              const Spacer(),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const DataFusionScreen(),
                    ),
                  );
                },
                child: const Text('Gabungkan Data'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}