import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/visual_analysis_result.dart';
import '../providers/ai_analysis_provider.dart';
import 'sensor_connection_screen.dart';

class AiAnalysisScreen extends StatefulWidget {
  final String photoType;
  const AiAnalysisScreen({super.key, required this.photoType});

  @override
  State<AiAnalysisScreen> createState() => _AiAnalysisScreenState();
}

class _AiAnalysisScreenState extends State<AiAnalysisScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AiAnalysisProvider>().analyze(
            photoType: widget.photoType,
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = AppTypography.textTheme;

    return Scaffold(
      backgroundColor: AppColors.cloudWhite,
      appBar: AppBar(title: const Text('Analisis AI')),
      body: SafeArea(
        child: Consumer<AiAnalysisProvider>(
          builder: (context, provider, _) {
            return Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: AppSpacing.lg),

                    // === IKON UTAMA ===
                    Center(
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: AppColors.aqua.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          provider.status == AiStatus.success
                              ? Icons.check
                              : Icons.auto_awesome,
                          color: AppColors.aqua,
                          size: 48,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // === JUDUL ===
                    Center(
                      child: Text(
                        provider.status == AiStatus.success
                            ? 'Analisis Selesai'
                            : 'Menganalisis foto...',
                        style: textTheme.headlineMedium,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // === LANGKAH PROGRESS ===
                    if (provider.status != AiStatus.success)
                      ...List.generate(provider.steps.length, (i) {
                        final done = i < provider.currentStep;
                        final active = i == provider.currentStep;
                        return Padding(
                          padding: const EdgeInsets.only(
                              bottom: AppSpacing.lg),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 24,
                                height: 24,
                                child: done
                                    ? const Icon(Icons.check_circle,
                                        color: AppColors.statusOnline,
                                        size: 22)
                                    : active
                                        ? const SizedBox(
                                            width: 18,
                                            height: 18,
                                            child:
                                                CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: AppColors.aqua,
                                            ),
                                          )
                                        : Icon(Icons.circle_outlined,
                                            color: AppColors.midGray,
                                            size: 20),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Text(
                                provider.steps[i],
                                style: textTheme.bodyMedium?.copyWith(
                                  color: done
                                      ? AppColors.charcoal
                                      : AppColors.midGray,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),

                    // === HASIL AI ===
                    if (provider.status == AiStatus.success &&
                        provider.result != null)
                      _resultCard(provider.result!),

                    // === ERROR ===
                    if (provider.status == AiStatus.error)
                      _errorCard(provider.error ?? 'Gagal menganalisis.'),

                    const SizedBox(height: AppSpacing.xxl),

                    // === TOMBOL ===
                    if (provider.status == AiStatus.success)
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  const SensorConnectionScreen(),
                            ),
                          );
                        },
                        child: const Text('Lanjut ke Sensor'),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _resultCard(VisualAnalysisResult r) {
    final textTheme = AppTypography.textTheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.softGray),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.visibility_outlined,
                  color: AppColors.aqua, size: 22),
              const SizedBox(width: AppSpacing.sm),
              Text('Indikator Visual', style: textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          _row('Kondisi', r.label),
          _row('Confidence', '${(r.confidence * 100).toStringAsFixed(0)}%'),
          _row('Warna dominan', r.dominantColor),
          _row('Tekstur', r.texture),
          _row('Pola permukaan', r.surfacePattern),

          const SizedBox(height: AppSpacing.md),
          Text(r.notes, style: textTheme.bodySmall),

          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.riskWaspadaBg,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline,
                    size: 16, color: AppColors.riskWaspada),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Indikator ini menunjukkan perubahan visual, '
                    'bukan identifikasi spesies atau toksin.',
                    style: textTheme.labelSmall,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    final textTheme = AppTypography.textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: textTheme.bodySmall),
          Text(value,
              style: textTheme.bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _errorCard(String message) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.riskDaruratBg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline,
              color: AppColors.riskDarurat),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(message,
                style: AppTypography.textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}