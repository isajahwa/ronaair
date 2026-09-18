import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import 'result_screen.dart';

class DataFusionScreen extends StatefulWidget {
  const DataFusionScreen({super.key});

  @override
  State<DataFusionScreen> createState() => _DataFusionScreenState();
}

class _DataFusionScreenState extends State<DataFusionScreen> {
  bool _done = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1800), () {
      if (mounted) setState(() => _done = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = AppTypography.textTheme;

    return Scaffold(
      backgroundColor: AppColors.cloudWhite,
      appBar: AppBar(title: const Text('Data Fusion')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Menggabungkan sumber data',
                style: textTheme.headlineMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Risk engine memadukan beberapa sumber evidence. '
                'Tidak ada satu parameter yang menentukan risiko sendiri.',
                style: textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.xl),

              _sourceCard(
                icon: Icons.auto_awesome,
                title: 'Analisis Visual AI',
                desc: 'Indikator visual dari foto air',
                color: AppColors.aqua,
              ),
              const SizedBox(height: AppSpacing.md),
              _sourceCard(
                icon: Icons.thermostat,
                title: 'Suhu Air',
                desc: 'Konteks dinamika DO',
                color: AppColors.statusInfo,
              ),
              const SizedBox(height: AppSpacing.md),
              _sourceCard(
                icon: Icons.science_outlined,
                title: 'pH',
                desc: 'Kondisi asam-basa',
                color: AppColors.statusInfo,
              ),
              const SizedBox(height: AppSpacing.md),
              _sourceCard(
                icon: Icons.water_drop_outlined,
                title: 'Turbidity',
                desc: 'Kekeruhan air',
                color: AppColors.statusInfo,
              ),
              const SizedBox(height: AppSpacing.md),
              _sourceCard(
                icon: Icons.bubble_chart_outlined,
                title: 'Estimated DO',
                desc: 'Estimasi dari MLR (soft sensor)',
                color: AppColors.statusInfo,
              ),

              const Spacer(),
              if (_done)
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (_) => const ResultScreen(),
                      ),
                    );
                  },
                  child: const Text('Lihat Hasil'),
                )
              else
                const Center(
                  child: Column(
                    children: [
                      CircularProgressIndicator(color: AppColors.aqua),
                      SizedBox(height: 12),
                      Text('Menghitung risk assessment...'),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sourceCard({
    required IconData icon,
    required String title,
    required String desc,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.softGray),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: AppTypography.textTheme.titleMedium),
                Text(desc,
                    style: AppTypography.textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}