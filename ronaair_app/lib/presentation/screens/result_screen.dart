import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../providers/assessment_provider.dart';
import 'explanation_screen.dart';
import 'package:provider/provider.dart';

class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AssessmentProvider>();
    final textTheme = AppTypography.textTheme;

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
              // === HEADER CARD RISK ===
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.xl),
                decoration: BoxDecoration(
                  color: _riskBackgroundColor(provider.riskLevelLabel),
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusXl),
                  border: Border.all(
                    color: _riskBorderColor(provider.riskLevelLabel),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Label risk status
                    Text(
                      provider.riskLevelLabel ?? 'PROVISIONAL',
                      style: textTheme.displayLarge?.copyWith(
                        color: _riskTextColor(provider.riskLevelLabel),
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),

                    // Data quality
                    Row(
                      children: [
                        Icon(
                          Icons.assessment,
                          size: 16,
                          color: AppColors.softGray,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          'Kualitas Data: ${provider.dataQuality ?? '—'}',
                          style: textTheme.bodySmall?.copyWith(
                            color: AppColors.softGray,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // === ESTIMATED DO ===
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusLg),
border: Border.all(
                  color: AppColors.softGray,
                  width: 1.0,
                ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.water_drop,
                      color: AppColors.aqua,
                      size: 20,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Estimated DO',
                            style: textTheme.bodySmall?.copyWith(
                              color: AppColors.softGray,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            provider.estimatedDo ?? '—',
                            style: textTheme.titleMedium?.copyWith(
                              color: AppColors.aqua,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // === REKOMENDASI ===
              Text(
                'Rekomendasi',
                style: textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.md),

              // Jika insufficient evidence
              if (provider.riskLevelLabel == 'DATA KURANG') ...[
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusLg),
                    border: Border.all(
                  color: AppColors.softGray,
                  width: 1.0,
                ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: AppColors.softGray,
                            size: 20,
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Text(
                              'Data pengukuran tidak cukup untuk menentukan risiko air kolam. '
                              'Silakan periksa kembali pengukuran nanti atau pastikan semua sensor terhubung dengan baik.',
                              style: textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _recommendationCard(
                        action: 'Cek koneksi sensor dan coba ulang pengukuran',
                        priority: 1,
                        recheckAfter: 60,
                        contraindication: '',
                        recommendationId: 'FALLBACK_000',
                        riskStatus: 'INSUFFICIENT_EVIDENCE',
                        source: 'fallback',
                        triggerCondition: 'NO_PYTHON_SERVICE',
                        validationStatus: 'NEEDS_EXPERT_VALIDATION',
                      ),
                    ],
                  ),
                ),
              ] else ...[
                ...List.generate(
                  provider.recommendations.length,
                  (index) => _recommendationCard(
                    action: provider.recommendations[index]['action'] ?? '',
                    priority: provider.recommendations[index]['priority'] as int?,
                    recheckAfter:
                        provider.recommendations[index]['recheck_after_minutes'] as int?,
                    contraindication:
                        provider.recommendations[index]['contraindication'] as String?,
                    recommendationId:
                        provider.recommendations[index]['recommendation_id'] as String?,
                    riskStatus:
                        provider.recommendations[index]['risk_status'] as String?,
                    source: provider.recommendations[index]['source'] as String?,
                    triggerCondition:
                        provider.recommendations[index]['trigger_condition'] as String?,
                    validationStatus:
                        provider.recommendations[index]['validation_status'] as String?,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.xxl),

              // === SUPPORTING FACTORS ===
              if (provider.supportingFactors.isNotEmpty) ...[
                Text(
                  'Faktor Pendukung',
                  style: textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.md),
                ...List.generate(
                  provider.supportingFactors.length,
                  (index) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusMd),
                        border: Border.all(
                          color: AppColors.softGray,
                          width: 1.0,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.info_outline,
                            size: 18,
                            color: AppColors.aqua,
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Text(
                              provider.supportingFactors[index],
                              style: textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ] else ...[
                const SizedBox(height: AppSpacing.md),
              ],

              const SizedBox(height: AppSpacing.xxl),

// === TOMBOL NAVIGASI ===
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                      side: const BorderSide(color: AppColors.aqua),
                      foregroundColor: AppColors.aqua,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusMd,
                        ),
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
                  const SizedBox(width: AppSpacing.md),
ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).popUntil((r) => r.isFirst);
                  },
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Selesai'),
                ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _riskBackgroundColor(String? riskLevel) {
    switch (riskLevel?.toUpperCase()) {
      case 'DARURAT':
        return AppColors.riskDaruratBg;
      case 'SIAGA':
        return AppColors.riskSiagaBg ?? Colors.orange.shade100;
      case 'WASPADA':
        return AppColors.riskWaspadaBg ?? Colors.yellow.shade100;
      case 'PROVISIONAL':
      case 'NORMAL':
      default:
        return AppColors.cloudWhite;
    }
  }

  Color _riskBorderColor(String? riskLevel) {
    switch (riskLevel?.toUpperCase()) {
      case 'DARURAT':
        return AppColors.riskDarurat;
      case 'SIAGA':
        return AppColors.riskSiaga;
      case 'WASPADA':
        return AppColors.riskWaspada;
      default:
        return AppColors.softGray;
    }
  }

  Color _riskTextColor(String? riskLevel) {
    switch (riskLevel?.toUpperCase()) {
      case 'DARURAT':
        return AppColors.riskDarurat;
      case 'SIAGA':
        return AppColors.riskSiaga;
      case 'WASPADA':
        return AppColors.riskWaspada;
      case 'PROVISIONAL':
        return AppColors.statusOnline;
      default:
        return AppColors.charcoal;
    }
  }

  Widget _recommendationCard({
    required String action,
    int? priority,
    int? recheckAfter,
    String? contraindication,
    String? recommendationId,
    String? riskStatus,
    String? source,
    String? triggerCondition,
    String? validationStatus,
  }) {
    final isHighPriority = priority == 1;
    final bgColor = isHighPriority
        ? AppColors.statusOnline.withValues(alpha: 0.05)
        : Colors.white;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
                  color: isHighPriority ? AppColors.statusOnline : AppColors.softGray,
                  width: 1.0,
                ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: isHighPriority ? AppColors.statusOnline : AppColors.statusError,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  action,
                  style: TextStyle(
                    color: isHighPriority ? AppColors.statusOnline : AppColors.charcoal,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isHighPriority
                      ? AppColors.statusOnline.withValues(alpha: 0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'P${priority != null ? priority : 1}',
                  style: TextStyle(
                    color: isHighPriority ? AppColors.statusOnline : AppColors.softGray,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
              if (triggerCondition != null && triggerCondition.isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.aqua.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '⚙️ $triggerCondition',
                    style: TextStyle(
                      color: AppColors.aqua,
                      fontSize: 10,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),

          if (contraindication != null && contraindication.isNotEmpty) ...[
            Row(
              children: [
                const Icon(
                  Icons.warning_amber_outlined,
                  size: 14,
                  color: AppColors.softGray,
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    'Larangan: $contraindication',
                    style: TextStyle(
                      color: AppColors.softGray,
                      fontSize: 12,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
          ],

          if (recheckAfter != null) ...[
            Row(
              children: [
                const Icon(
                  Icons.access_time,
                  size: 14,
                  color: AppColors.softGray,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  'Ulangi dalam $recheckAfter menit',
                  style: TextStyle(
                    color: AppColors.softGray,
                    fontSize: 12,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
          ],

          const SizedBox(height: AppSpacing.md),

          Row(
            children: [
const Icon(
                  Icons.hourglass_empty,
                  size: 14,
                  color: AppColors.softGray,
                ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  'Validasi: $validationStatus',
                  style: TextStyle(
                    color: AppColors.softGray,
                    fontSize: 11,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}