import 'package:flutter/material.dart';
import 'dart:math';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../providers/ai_analysis_provider.dart';
import 'ai_analysis_screen.dart';

class QualityCheckScreen extends StatefulWidget {
  final String photoType;
  const QualityCheckScreen({super.key, required this.photoType});

  @override
  State<QualityCheckScreen> createState() => _QualityCheckScreenState();
}

class _QualityCheckScreenState extends State<QualityCheckScreen> {
  bool _valid = false;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _runCheck();
  }

  Future<void> _runCheck() async {
    await Future.delayed(const Duration(milliseconds: 1400));
    // 80% valid
    final random = Random();
    setState(() {
      _valid = random.nextDouble() > 0.2;
      _done = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = AppTypography.textTheme;

    return Scaffold(
      backgroundColor: AppColors.cloudWhite,
      appBar: AppBar(title: const Text('Pemeriksaan Kualitas Foto')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: !_done
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: AppColors.aqua),
                      SizedBox(height: 16),
                      Text('Memeriksa kualitas foto...'),
                    ],
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Preview
                    Container(
                      height: 200,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F1A20),
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusLg),
                      ),
                      child: Center(
                        child: Icon(
                          widget.photoType == 'water'
                              ? Icons.water
                              : Icons.science_outlined,
                          size: 80,
                          color: Colors.white.withValues(alpha: 0.3),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // Hasil cek
                    Text('Hasil Pemeriksaan',
                        style: textTheme.titleMedium),
                    const SizedBox(height: AppSpacing.md),
                    _check('Ketajaman foto (blur)', _valid),
                    _check('Pencahayaan (exposure)', _valid),
                    _check('Pantulan cahaya (glare)', _valid),
                    _check('Framing & keberadaan RonaCard', _valid),

                    const Spacer(),

                    if (_valid)
                      ElevatedButton.icon(
                        onPressed: () {
                          // Reset provider agar mulai dari state bersih.
                          context.read<AiAnalysisProvider>().reset();
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => AiAnalysisScreen(
                                photoType: widget.photoType,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.check_circle_outline),
                        label: const Text('Lanjut Analisis AI'),
                      )
                    else
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.riskWaspada,
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Ambil Ulang Foto'),
                      ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _check(String label, bool ok) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        children: [
          Icon(
            ok ? Icons.check_circle : Icons.cancel,
            color:
                ok ? AppColors.statusOnline : AppColors.statusError,
            size: 20,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              label,
              style: AppTypography.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}