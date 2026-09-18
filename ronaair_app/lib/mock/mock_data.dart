import '../data/models/risk_level.dart';

/// Data mock untuk pengembangan UI.
/// GANTI dengan data asli saat backend & AI siap.
class MockSensorData {
  final double temperature;
  final double ph;
  final double turbidity;
  final double estimatedDo;
  final DateTime recordedAt;

  const MockSensorData({
    required this.temperature,
    required this.ph,
    required this.turbidity,
    required this.estimatedDo,
    required this.recordedAt,
  });
}

/// Data mock utama yang dipakai UI.
class MockData {
  MockData._();

  /// Data sensor terakhir.
  static MockSensorData currentSensor = MockSensorData(
    temperature: 28.5,
    ph: 7.2,
    turbidity: 15.3,
    estimatedDo: 6.1,
    recordedAt: DateTime.now().subtract(const Duration(minutes: 2)),
  );

  /// Status risiko saat ini.
  static RiskLevel currentRisk = RiskLevel.waspada;

  /// Faktor yang mempengaruhi status risiko.
  static const List<String> currentFactors = [
    'Turbidity meningkat',
    'pH sedikit menurun',
    'Suhu normal',
  ];

  /// Penjelasan singkat.
  static const String currentExplanation =
      'Kondisi air menunjukkan perubahan yang perlu dipantau. '
      'Turbidity sedikit di atas rentang normal.';

  /// Rekomendasi tindakan.
  static const List<String> currentRecommendations = [
    'Periksa kembali kondisi air.',
    'Pantau perubahan warna dan permukaan.',
    'Periksa parameter kualitas air lebih sering.',
  ];

  /// Histori pemeriksaan (mock).
  static final List<MockHistoryItem> history = [
    MockHistoryItem(
      date: DateTime.now().subtract(const Duration(hours: 2)),
      risk: RiskLevel.waspada,
      temperature: 28.5,
      ph: 7.2,
    ),
    MockHistoryItem(
      date: DateTime.now().subtract(const Duration(hours: 8)),
      risk: RiskLevel.normal,
      temperature: 27.8,
      ph: 7.0,
    ),
    MockHistoryItem(
      date: DateTime.now().subtract(const Duration(days: 1)),
      risk: RiskLevel.siaga,
      temperature: 29.2,
      ph: 6.8,
    ),
    MockHistoryItem(
      date: DateTime.now().subtract(const Duration(days: 2)),
      risk: RiskLevel.normal,
      temperature: 28.0,
      ph: 7.1,
    ),
  ];

  /// Simulasi status koneksi & sensor.
  static const bool isOnline = true;
  static const bool isSensorConnected = true;
  static const bool isAiAvailable = true;
}

class MockHistoryItem {
  final DateTime date;
  final RiskLevel risk;
  final double temperature;
  final double ph;

  const MockHistoryItem({
    required this.date,
    required this.risk,
    required this.temperature,
    required this.ph,
  });
}