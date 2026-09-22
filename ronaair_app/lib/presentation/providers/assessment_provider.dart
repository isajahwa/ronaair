import 'package:flutter/foundation.dart';

enum AssessmentStatus { idle, analyzing, success, error, insufficientEvidence }

class AssessmentProvider extends ChangeNotifier {
  AssessmentStatus _status = AssessmentStatus.idle;
  Map<String, dynamic>? _result;
  String? _error;
  String? _riskLevelLabel;
  String? _dataQuality;
  String? _estimatedDo;
  List<Map<String, dynamic>> _recommendations = [];
  List<String> _supportingFactors = [];
  String? _decisionSource;
  String? _modelVersion;
  String? _timestamp;

  AssessmentStatus get status => _status;
  Map<String, dynamic>? get result => _result;
  String? get error => _error;
  String? get riskLevelLabel => _riskLevelLabel;
  String? get dataQuality => _dataQuality;
  String? get estimatedDo => _estimatedDo;
  List<Map<String, dynamic>> get recommendations => _recommendations;
  List<String> get supportingFactors => _supportingFactors;
  String? get decisionSource => _decisionSource;
  String? get modelVersion => _modelVersion;
  String? get timestamp => _timestamp;

  void reset() {
    _status = AssessmentStatus.idle;
    _result = null;
    _error = null;
    _riskLevelLabel = null;
    _dataQuality = null;
    _estimatedDo = null;
    _recommendations = [];
    _supportingFactors = [];
    _decisionSource = null;
    _modelVersion = null;
    _timestamp = null;
    notifyListeners();
  }

  Future<void> assess({
    required double waterTemp,
    required double phSensor,
    required double? doEst,
    required double visualScore,
    required double? phVisualEst,
    required String imageQuality,
    required double? phDifference,
    required double? ecValue,
    required double? tdsPpm,
    required int hour,
  }) async {
    _status = AssessmentStatus.analyzing;
    _result = null;
    _error = null;
    _recommendations = [];
    _supportingFactors = [];
    notifyListeners();

    try {
      // TODO: Panggil _api.postAssess saat backend ready
      _simulateAssessment();
      _status = AssessmentStatus.success;
    } catch (e) {
      _error = e.toString();
      _status = AssessmentStatus.error;
    }
    notifyListeners();
  }

  void _simulateAssessment() {
    _result = {
      'risk_status': 'INSUFFICIENT_EVIDENCE',
      'data_quality': 'LIMITED',
      'recommendations': [
        {
          'action': 'Cek sensor dan coba ulang',
          'priority': 1,
          'recheck_after_minutes': 60,
          'recommendation_id': 'FALLBACK_000',
          'risk_status': 'INSUFFICIENT_EVIDENCE',
          'source': 'fallback',
          'trigger_condition': 'NO_PYTHON_SERVICE',
          'validation_status': 'NEEDS_EXPERT_VALIDATION',
        }
      ],
      'supporting_factors': ['Sensor tidak terbaca'],
      'decision_source': 'fallback',
      'model_version': 'unavailable',
      'timestamp': DateTime.now().toIso8601String(),
    };
    _parseResult(_result!);
  }

  void _parseResult(Map<String, dynamic> json) {
    final riskStatus = json['risk_status'] as String? ?? 'INSUFFICIENT_EVIDENCE';
    _riskLevelLabel = _mapRiskStatus(riskStatus);
    _dataQuality = json['data_quality'] as String? ?? 'UNKNOWN';
    _estimatedDo = _extractEstimatedDo(json);
    final rawRecs = json['recommendations'] as List<dynamic>? ?? [];
    _recommendations = _normalizeRecommendations(rawRecs);
    _supportingFactors = (json['supporting_factors'] as List<dynamic>? ?? [])
    .cast<String>()
    .toList();
    _decisionSource = json['decision_source'] as String? ?? 'unknown';
    _modelVersion = json['model_version'] as String? ?? '';
    _timestamp = json['timestamp'] as String? ?? '';
  }

  String _mapRiskStatus(String status) {
    switch (status.toUpperCase()) {
      case 'NORMAL': return 'PROVISIONAL';
      case 'WASPADA': return 'WASPADA';
      case 'SIAGA': return 'SIAGA';
      case 'DARURAT': return 'DARURAT';
      case 'INSUFFICIENT_EVIDENCE': return 'DATA KURANG';
      default: return 'PROVISIONAL';
    }
  }

  String? _extractEstimatedDo(Map<String, dynamic> json) {
    final rules = json['fired_rules'] as List<dynamic>?;
    if (rules != null && rules.isNotEmpty) {
      final lastRule = rules.last;
      if (lastRule is Map<String, dynamic>) {
        final doVal = lastRule['estimated_do'] ?? lastRule['do_est'];
        if (doVal != null) return _formatDo(doVal);
      }
    }
    final recs = json['recommendations'] as List<dynamic>?;
    if (recs != null && recs.isNotEmpty) {
      final firstRec = recs.first;
      if (firstRec is Map<String, dynamic>) {
        final doVal = firstRec['estimated_do'];
        if (doVal != null) return _formatDo(doVal);
      }
    }
    return null;
  }

  String _formatDo(dynamic val) {
    if (val is num) return '${val.toStringAsFixed(1)} mg/L';
    if (val is String) {
      final extracted = double.tryParse(val.replaceAll('mg/L', '').trim());
      if (extracted != null) return '${extracted.toStringAsFixed(1)} mg/L';
    }
    return '${val.toString()} mg/L';
  }

  List<Map<String, dynamic>> _normalizeRecommendations(List<dynamic> raw) {
    final result = <Map<String, dynamic>>[];
    for (final rec in raw) {
      if (rec is! Map<String, dynamic>) continue;
      result.add({
        'action': rec['action'] ?? '',
        'contraindication': rec['contraindication'] ?? '',
        'priority': _normalizePriority(rec['priority']),
        'recheck_after_minutes': _normalizeRecheckAfter(rec['recheck_after_minutes']),
        'recommendation_id': rec['recommendation_id'] ?? 'RISK_000',
        'risk_status': rec['risk_status'] ?? 'INSUFFICIENT_EVIDENCE',
        'source': rec['source'] ?? 'unknown',
        'trigger_condition': _normalizeTrigger(rec),
        'validation_status': rec['validation_status'] ?? 'NEEDS_EXPERT_VALIDATION',
      });
    }
    result.sort((a, b) =>
        (_normalizePriority(a['priority']) ?? 99)
            .compareTo(_normalizePriority(b['priority']) ?? 99));
    return result;
  }

  int _normalizePriority(dynamic priority) {
    if (priority is int) return priority;
    if (priority is double) {
      if (priority <= 1.5) return 1;
      if (priority <= 2.5) return 2;
      return 3;
    }
    if (priority is String) {
      switch (priority.toLowerCase()) {
        case 'high':
        case '1': return 1;
        case 'medium':
        case '2': return 2;
        case 'low':
        case '3': return 3;
        default: return 1;
      }
    }
    return 1;
  }

  int _normalizeRecheckAfter(dynamic minutes) {
    if (minutes is int) return minutes;
    if (minutes is double) return minutes.round();
    if (minutes is String) {
      final extracted = int.tryParse(minutes.replaceAll(' menit', '').trim());
      if (extracted != null) return extracted;
    }
    return 60;
  }

  String _normalizeTrigger(dynamic trigger) {
    if (trigger is String) {
      return trigger;
    }
    if (trigger is Map<String, dynamic>) {
      return trigger['trigger_condition'] ?? '';
    }
    return '';
  }
}