import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/risk_level.dart';
import '../providers/history_provider.dart';
import '../widgets/history_item.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HistoryProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = AppTypography.textTheme;

    return Scaffold(
      backgroundColor: AppColors.cloudWhite,
      appBar: AppBar(
        title: const Text('Riwayat Pemeriksaan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<HistoryProvider>().refresh(),
          ),
        ],
      ),
      body: SafeArea(
        child: Consumer<HistoryProvider>(
          builder: (context, provider, _) {
            // Loading
            if (provider.isLoading && provider.items.isEmpty) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.aqua),
              );
            }

            // Error
            if (provider.error != null && provider.items.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.cloud_off,
                          size: 64, color: AppColors.midGray),
                      const SizedBox(height: AppSpacing.lg),
                      Text(provider.error!,
                          style: textTheme.bodyMedium,
                          textAlign: TextAlign.center),
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

            // Empty
            if (provider.items.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.history,
                          size: 64, color: AppColors.midGray),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        'Belum ada riwayat pemeriksaan.',
                        style: textTheme.bodyMedium,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Lakukan Periksa Kolam untuk memulai.',
                        style: textTheme.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }

            // Success
            return RefreshIndicator(
              color: AppColors.aqua,
              onRefresh: () => provider.refresh(),
              child: Column(
                children: [
                  if (provider.isOffline)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpacing.md),
                      color: AppColors.riskWaspadaBg,
                      child: Text(
                        'Offline — menampilkan riwayat terakhir',
                        style: textTheme.labelSmall,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      itemCount: provider.items.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (_, i) {
                        final item = provider.items[i];
                        final risk = RiskLevelX.fromString(
                          item['risk_level'] ?? 'NORMAL',
                        );
                        final time = item['started_at'] != null
                            ? DateTime.tryParse(item['started_at']) ??
                                DateTime.now()
                            : DateTime.now();

                        final temp = item['temperature'];
                        final ph = item['ph'];
                        final summary = 'Suhu ${temp ?? '—'}°C • pH ${ph ?? '—'}';

                        return HistoryItem(
                          risk: risk,
                          date: time,
                          summary: summary,
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}