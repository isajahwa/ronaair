import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/risk_level.dart';
import '../providers/dashboard_provider.dart';
import '../widgets/connection_status.dart';
import '../widgets/recommendation_card.dart';
import '../widgets/sensor_card.dart';
import '../widgets/warning_card.dart';
import 'photo_capture_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Muat data saat pertama kali dibuka.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = AppTypography.textTheme;

    return Scaffold(
      backgroundColor: AppColors.cloudWhite,
      body: SafeArea(
        child: Consumer<DashboardProvider>(
          builder: (context, provider, _) {
            // === Loading state ===
            if (provider.status == LoadStatus.loading &&
                provider.data == null) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.aqua),
              );
            }

            // === Error state ===
            if (provider.status == LoadStatus.error &&
                provider.data == null) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.cloud_off,
                          size: 64, color: AppColors.midGray),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        provider.errorMessage ?? 'Gagal memuat data.',
                        style: textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      ElevatedButton(
                        onPressed: () => provider.refresh(),
                        child: const Text('Coba Lagi'),
                      ),
                    ],
                  ),
                ),
              );
            }

            // === Success state ===
            final data = provider.data!;
            final sensor = data.sensor;
            final risk = data.riskLevel;

            return RefreshIndicator(
              color: AppColors.aqua,
              onRefresh: () => provider.refresh(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // === HEADER ===
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(data.pondName,
                                style: textTheme.titleMedium),
                            const SizedBox(height: 4),
                            ConnectionStatus(
                              isOnline: !provider.isOffline,
                              lastUpdated: provider.cachedAt,
                            ),
                          ],
                        ),
                        IconButton(
                          onPressed: () => provider.refresh(),
                          icon: const Icon(Icons.refresh),
                        ),
                      ],
                    ),

                    // === OFFLINE BANNER ===
                    if (provider.isOffline) ...[
                      const SizedBox(height: AppSpacing.md),
                      Container(
                        padding:
                            const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.riskWaspadaBg,
                          borderRadius: BorderRadius.circular(
                              AppSpacing.radiusMd),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.cloud_off,
                                color: AppColors.riskWaspada, size: 20),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                provider.errorMessage ??
                                    'Offline — menampilkan data terakhir.',
                                style: textTheme.bodySmall,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: AppSpacing.xl),

                    // === RISK BESAR ===
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      decoration: BoxDecoration(
                        color: risk.backgroundColor,
                        borderRadius: BorderRadius.circular(
                            AppSpacing.radiusXl),
                        border: Border.all(
                            color: risk.color.withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Status Kolam',
                              style: textTheme.bodySmall),
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
                    const SizedBox(height: AppSpacing.lg),

                    // === WARNING ===
                    WarningCard(
                      level: risk,
                      message: data.explanation,
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // === SENSOR SECTION ===
                    Text('Parameter Air',
                        style: textTheme.titleMedium),
                    const SizedBox(height: AppSpacing.md),

                    // Kalau sensor null → empty state
                    if (sensor == null)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppSpacing.xl),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(
                              AppSpacing.radiusLg),
                          border:
                              Border.all(color: AppColors.softGray),
                        ),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.sensors_off,
                              size: 48,
                              color: AppColors.midGray,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              'Belum ada data sensor',
                              style: textTheme.titleMedium,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              'Pastikan perangkat ESP32 terhubung dan mengirim data.',
                              style: textTheme.bodySmall,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    // Kalau ada → grid sensor
                    else
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics:
                            const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: AppSpacing.md,
                        crossAxisSpacing: AppSpacing.md,
                        childAspectRatio: 1.35,
                        children: [
                          SensorCard(
                            icon: Icons.thermostat,
                            label: 'Suhu',
                            value: sensor.temperature
                                    ?.toStringAsFixed(1) ??
                                '—',
                            unit: '°C',
                          ),
                          SensorCard(
                            icon: Icons.science_outlined,
                            label: 'pH',
                            value:
                                sensor.ph?.toStringAsFixed(1) ?? '—',
                            unit: '',
                          ),
                          SensorCard(
                            icon: Icons.water_drop_outlined,
                            label: 'Turbidity',
                            value: sensor.turbidity
                                    ?.toStringAsFixed(1) ??
                                '—',
                            unit: 'NTU',
                          ),
                          SensorCard(
                            icon: Icons.bubble_chart_outlined,
                            label: 'Est. DO',
                            value: sensor.estimatedDo
                                    ?.toStringAsFixed(1) ??
                                '—',
                            unit: 'mg/L',
                          ),
                        ],
                      ),
                    const SizedBox(height: AppSpacing.xl),

                    // === TOMBOL PERIKSA ===
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                const PhotoCaptureScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.add_a_photo_outlined),
                      label: const Text('Periksa Kolam'),
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // === REKOMENDASI ===
                    RecommendationCard(
                      recommendations: [data.recommendation],
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // === FAKTOR (info tambahan) ===
                    if (data.factors.isNotEmpty) ...[
                      Text('Faktor Kontribusi',
                          style: textTheme.titleMedium),
                      const SizedBox(height: AppSpacing.md),
                      ...data.factors.map(
                        (f) => Padding(
                          padding: const EdgeInsets.only(
                              bottom: AppSpacing.sm),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline,
                                  size: 16, color: risk.color),
                              const SizedBox(
                                  width: AppSpacing.sm),
                              Expanded(
                                child: Text(f,
                                    style:
                                        textTheme.bodyMedium),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: AppSpacing.xxl),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}