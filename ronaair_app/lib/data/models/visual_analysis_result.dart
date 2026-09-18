/// Hasil analisis visual dari AI (atau mock AI).
///
/// ⚠️ CATATAN PENTING:
/// Field di sini adalah kontrak SEMENTARA dengan tim AI.
/// Jangan menambahkan klaim diagnosis (spesies/toksin).
class VisualAnalysisResult {
  final String visualIndicator; // "normal", "waspada", "siaga"
  final double confidence;      // 0.0 – 1.0
  final bool blur;
  final bool glare;
  final bool exposureOk;
  final String dominantColor;
  final String texture;
  final String surfacePattern;
  final String notes;

  const VisualAnalysisResult({
    required this.visualIndicator,
    required this.confidence,
    this.blur = false,
    this.glare = false,
    this.exposureOk = true,
    this.dominantColor = '-',
    this.texture = '-',
    this.surfacePattern = '-',
    this.notes = '',
  });

  factory VisualAnalysisResult.fromJson(Map<String, dynamic> json) {
    final flags = json['quality_flags'] as Map<String, dynamic>? ?? {};
    final features = json['features'] as Map<String, dynamic>? ?? {};

    return VisualAnalysisResult(
      visualIndicator: json['visual_indicator'] ?? 'normal',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      blur: flags['blur'] ?? false,
      glare: flags['glare'] ?? false,
      exposureOk: flags['exposure_ok'] ?? true,
      dominantColor: features['dominant_color'] ?? '-',
      texture: features['texture'] ?? '-',
      surfacePattern: features['surface_pattern'] ?? '-',
      notes: json['notes'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'visual_indicator': visualIndicator,
      'confidence': confidence,
      'quality_flags': {
        'blur': blur,
        'glare': glare,
        'exposure_ok': exposureOk,
      },
      'features': {
        'dominant_color': dominantColor,
        'texture': texture,
        'surface_pattern': surfacePattern,
      },
      'notes': notes,
    };
  }

  /// Label ramah pengguna.
  String get label {
    switch (visualIndicator.toLowerCase()) {
      case 'normal':
        return 'Normal';
      case 'waspada':
        return 'Waspada';
      case 'siaga':
        return 'Siaga';
      default:
        return 'Tidak diketahui';
    }
  }
}