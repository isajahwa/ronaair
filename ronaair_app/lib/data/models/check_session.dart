import 'risk_level.dart';

/// Data satu sesi pemeriksaan (mock).
class CheckSession {
  final String? photoPath;
  final bool photoValid;
  final String? visualIndicator;
  final double? visualConfidence;

  final double? temperature;
  final double? ph;
  final double? turbidity;
  final double? estimatedDo;

  final RiskLevel risk;
  final List<String> factors;
  final String explanation;
  final List<String> recommendations;

  const CheckSession({
    this.photoPath,
    this.photoValid = false,
    this.visualIndicator,
    this.visualConfidence,
    this.temperature,
    this.ph,
    this.turbidity,
    this.estimatedDo,
    this.risk = RiskLevel.normal,
    this.factors = const [],
    this.explanation = '',
    this.recommendations = const [],
  });

  CheckSession copyWith({
    String? photoPath,
    bool? photoValid,
    String? visualIndicator,
    double? visualConfidence,
    double? temperature,
    double? ph,
    double? turbidity,
    double? estimatedDo,
    RiskLevel? risk,
    List<String>? factors,
    String? explanation,
    List<String>? recommendations,
  }) {
    return CheckSession(
      photoPath: photoPath ?? this.photoPath,
      photoValid: photoValid ?? this.photoValid,
      visualIndicator: visualIndicator ?? this.visualIndicator,
      visualConfidence: visualConfidence ?? this.visualConfidence,
      temperature: temperature ?? this.temperature,
      ph: ph ?? this.ph,
      turbidity: turbidity ?? this.turbidity,
      estimatedDo: estimatedDo ?? this.estimatedDo,
      risk: risk ?? this.risk,
      factors: factors ?? this.factors,
      explanation: explanation ?? this.explanation,
      recommendations: recommendations ?? this.recommendations,
    );
  }
}