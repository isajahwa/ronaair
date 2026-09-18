import 'risk_level.dart';

/// Data dashboard dari backend.
class DashboardData {
  final int pondId;
  final String pondName;
  final RiskLevel riskLevel;
  final List<String> factors;
  final String explanation;
  final String recommendation;
  final SensorData? sensor;
  final DateTime? lastUpdated;
  final bool isOnline;
  final bool isSensorConnected;

  const DashboardData({
    required this.pondId,
    required this.pondName,
    required this.riskLevel,
    required this.factors,
    required this.explanation,
    required this.recommendation,
    this.sensor,
    this.lastUpdated,
    required this.isOnline,
    required this.isSensorConnected,
  });

  /// Konversi dari JSON API.
  factory DashboardData.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? json;

    return DashboardData(
      pondId: data['pond_id'] ?? 0,
      pondName: data['pond_name'] ?? 'Kolam',
      riskLevel: RiskLevelX.fromString(data['risk_level'] ?? 'NORMAL'),
      factors: (data['factors'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      explanation: data['explanation'] ?? '',
      recommendation: data['recommendation'] ?? '',
      sensor: data['sensor'] != null
          ? SensorData.fromJson(data['sensor'])
          : null,
      lastUpdated: data['last_updated'] != null
          ? DateTime.tryParse(data['last_updated'])
          : null,
      isOnline: data['is_online'] ?? false,
      isSensorConnected: data['is_sensor_connected'] ?? false,
    );
  }

  /// Konversi ke JSON untuk disimpan di cache.
  Map<String, dynamic> toJson() {
    return {
      'pond_id': pondId,
      'pond_name': pondName,
      'risk_level': riskLevel.label,
      'factors': factors,
      'explanation': explanation,
      'recommendation': recommendation,
      'sensor': sensor?.toJson(),
      'last_updated': lastUpdated?.toIso8601String(),
      'is_online': isOnline,
      'is_sensor_connected': isSensorConnected,
    };
  }
}

/// Data sensor dari backend.
class SensorData {
  final double? temperature;
  final double? ph;
  final double? turbidity;
  final double? estimatedDo;
  final DateTime? recordedAt;

  const SensorData({
    this.temperature,
    this.ph,
    this.turbidity,
    this.estimatedDo,
    this.recordedAt,
  });

  factory SensorData.fromJson(Map<String, dynamic> json) {
    return SensorData(
      temperature: (json['temperature'] as num?)?.toDouble(),
      ph: (json['ph'] as num?)?.toDouble(),
      turbidity: (json['turbidity'] as num?)?.toDouble(),
      estimatedDo: (json['estimated_do'] as num?)?.toDouble(),
      recordedAt: json['recorded_at'] != null
          ? DateTime.tryParse(json['recorded_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'temperature': temperature,
      'ph': ph,
      'turbidity': turbidity,
      'estimated_do': estimatedDo,
      'recorded_at': recordedAt?.toIso8601String(),
    };
  }
}