import 'package:flutter/foundation.dart';
import '../../data/models/visual_analysis_result.dart';
import '../../mock/mock_ai_service.dart';

enum AiStatus { idle, running, success, error }

/// Provider state untuk proses analisis AI.
class AiAnalysisProvider extends ChangeNotifier {
  final MockAiService _service;

  AiAnalysisProvider({MockAiService? service})
      : _service = service ?? MockAiService();

  AiStatus _status = AiStatus.idle;
  VisualAnalysisResult? _result;
  String? _error;
  int _step = 0;

  final List<String> _steps = const [
    'Preprocessing citra',
    'Ekstraksi fitur warna & tekstur',
    'Analisis model visual',
    'Menyusun indikator visual',
  ];

  AiStatus get status => _status;
  VisualAnalysisResult? get result => _result;
  String? get error => _error;
  int get currentStep => _step;
  List<String> get steps => _steps;

  /// Setel mode AI untuk demo.
  void setMode(MockAiMode mode) {
    _service.mode = mode;
  }

  /// Jalankan analisis.
  Future<void> analyze({
    required String photoType,
    String? imagePath,
  }) async {
    _status = AiStatus.running;
    _step = 0;
    _result = null;
    _error = null;
    notifyListeners();

    // Simulasi progres langkah
    for (int i = 0; i < _steps.length; i++) {
      await Future.delayed(const Duration(milliseconds: 400));
      _step = i + 1;
      notifyListeners();
    }

    try {
      final result = await _service.analyze(
        photoType: photoType,
        imagePath: imagePath,
      );
      _result = result;
      _status = AiStatus.success;
    } catch (e) {
      _error = 'Gagal menganalisis foto: $e';
      _status = AiStatus.error;
    }
    notifyListeners();
  }

  void reset() {
    _status = AiStatus.idle;
    _step = 0;
    _result = null;
    _error = null;
    notifyListeners();
  }
}