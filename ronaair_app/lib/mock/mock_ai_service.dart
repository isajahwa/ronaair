import 'dart:math';
import '../data/models/visual_analysis_result.dart';

/// Mode simulasi AI.
enum MockAiMode { auto, normal, waspada, siaga }

/// Mock AI Service — pengganti sementara model AI asli.
///
/// ⚠️ Ini SIMULASI. Tidak ada model ML yang berjalan di sini.
/// Output hanya untuk menguji alur UI, bukan klaim ilmiah.
class MockAiService {
  /// Ubah mode ini untuk demo. Default `auto` = random realistis.
  MockAiMode mode = MockAiMode.auto;

  /// Simulasi proses analisis AI.
  /// Delay ~2–3 detik agar terasa seperti AI benar-benar bekerja.
  Future<VisualAnalysisResult> analyze({
    required String photoType, // "water" atau "litmus"
    String? imagePath,
  }) async {
    // Simulasi waktu proses AI
    final delayMs = 1800 + Random().nextInt(1200);
    await Future.delayed(Duration(milliseconds: delayMs));

    // Pilih mode jika auto
    MockAiMode effectiveMode = mode;
    if (mode == MockAiMode.auto) {
      final r = Random().nextDouble();
      if (r < 0.55) {
        effectiveMode = MockAiMode.normal;
      } else if (r < 0.85) {
        effectiveMode = MockAiMode.waspada;
      } else {
        effectiveMode = MockAiMode.siaga;
      }
    }

    // Bangun output berdasarkan mode
    switch (effectiveMode) {
      case MockAiMode.normal:
        return _normal(photoType);
      case MockAiMode.waspada:
        return _waspada(photoType);
      case MockAiMode.siaga:
        return _siaga(photoType);
      case MockAiMode.auto:
        return _normal(photoType); // fallback
    }
  }

  VisualAnalysisResult _normal(String photoType) {
    return VisualAnalysisResult(
      visualIndicator: 'normal',
      confidence: 0.86 + Random().nextDouble() * 0.1,
      dominantColor: photoType == 'litmus' ? 'kuning-hijau' : 'hijau jernih',
      texture: 'halus',
      surfacePattern: 'permukaan tenang',
      notes: 'Karakteristik visual air dalam kondisi stabil. '
          'Tidak ada perubahan signifikan dibanding kondisi normal.',
    );
  }

  VisualAnalysisResult _waspada(String photoType) {
    return VisualAnalysisResult(
      visualIndicator: 'waspada',
      confidence: 0.72 + Random().nextDouble() * 0.12,
      dominantColor:
          photoType == 'litmus' ? 'hijau tua' : 'hijau kecoklatan',
      texture: 'sedang',
      surfacePattern: 'ada partikel halus di permukaan',
      notes: 'Terdeteksi perubahan warna dan tekstur ringan. '
          'Kondisi visual perlu dipantau lebih lanjut.',
    );
  }

  VisualAnalysisResult _siaga(String photoType) {
    return VisualAnalysisResult(
      visualIndicator: 'siaga',
      confidence: 0.78 + Random().nextDouble() * 0.12,
      dominantColor: photoType == 'litmus' ? 'biru tua' : 'hijau pekat',
      texture: 'kasar',
      surfacePattern: 'ada lapisan/scum di permukaan',
      notes: 'Perubahan visual cukup jelas. Perlu pemeriksaan '
          'lanjutan dan validasi kondisi air.',
    );
  }
}