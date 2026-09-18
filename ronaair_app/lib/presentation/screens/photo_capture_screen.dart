import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import 'quality_check_screen.dart';

class PhotoCaptureScreen extends StatefulWidget {
  const PhotoCaptureScreen({super.key});

  @override
  State<PhotoCaptureScreen> createState() => _PhotoCaptureScreenState();
}

class _PhotoCaptureScreenState extends State<PhotoCaptureScreen> {
  int _mode = 0; // 0 = air, 1 = lakmus

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Ambil Foto'),
      ),
      body: Stack(
        children: [
          // === VIEWFINDER MOCK ===
          Positioned.fill(
            child: Container(
              color: const Color(0xFF0F1A20),
              child: Center(
                child: Icon(
                  _mode == 0 ? Icons.water : Icons.science_outlined,
                  size: 120,
                  color: Colors.white.withOpacity(0.15),
                ),
              ),
            ),
          ),

          // === FRAMING GUIDE ===
          Center(
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.aqua, width: 2),
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              ),
            ),
          ),

          // === PANDUAN ATAS ===
          Positioned(
            top: 80,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Text(
                  _mode == 0
                      ? 'Arahkan ke permukaan air kolam'
                      : 'Letakkan kertas lakmus di tengah',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  'Jaga jarak 20–30 cm • Hindari pantulan cahaya',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          // === INDIKATOR CAHAYA ===
          Positioned(
            top: 140,
            right: 24,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.wb_sunny_outlined,
                      color: Colors.amber, size: 14),
                  SizedBox(width: 4),
                  Text('Cahaya cukup',
                      style: TextStyle(
                          color: Colors.white, fontSize: 11)),
                ],
              ),
            ),
          ),

          // === MODE TOGGLE BAWAH ===
          Positioned(
            bottom: 160,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _modeChip('Foto Air', 0),
                const SizedBox(width: 8),
                _modeChip('Kertas Lakmus', 1),
              ],
            ),
          ),

          // === TOMBOL CAPTURE ===
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => QualityCheckScreen(
                        photoType: _mode == 0 ? 'water' : 'litmus',
                      ),
                    ),
                  );
                },
                child: Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                  ),
                  child: Container(
                    margin: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.aqua,
                    ),
                    child: const Icon(Icons.camera_alt,
                        color: Colors.white, size: 32),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _modeChip(String label, int index) {
    final active = _mode == index;
    return GestureDetector(
      onTap: () => setState(() => _mode = index),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active
              ? AppColors.aqua
              : Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}