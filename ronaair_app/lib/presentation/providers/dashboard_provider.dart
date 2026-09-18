import 'package:flutter/foundation.dart';
import '../../data/models/dashboard_data.dart';
import '../../data/repositories/ronaair_repository.dart';

/// Status pemuatan data di UI.
enum LoadStatus { initial, loading, success, error }

/// Provider yang mengatur state Dashboard.
class DashboardProvider extends ChangeNotifier {
  final RonaAirRepository repository;

  DashboardProvider({RonaAirRepository? repository})
      : repository = repository ?? RonaAirRepository();

  LoadStatus _status = LoadStatus.initial;
  DashboardData? _data;
  bool _isOffline = false;
  DateTime? _cachedAt;
  String? _errorMessage;

  // Getter
  LoadStatus get status => _status;
  DashboardData? get data => _data;
  bool get isOffline => _isOffline;
  DateTime? get cachedAt => _cachedAt;
  String? get errorMessage => _errorMessage;

  /// Muat data dashboard dari repository.
  Future<void> load({int pondId = 1}) async {
    _status = LoadStatus.loading;
    _errorMessage = null;
    notifyListeners();

    final result = await repository.getDashboard(pondId: pondId);

    if (result.hasData) {
      _data = result.data;
      _isOffline = result.isFromCache;
      _cachedAt = result.cachedAt;
      _status = LoadStatus.success;
    } else {
      _errorMessage = result.errorMessage ?? 'Gagal memuat data.';
      _status = LoadStatus.error;
    }

    notifyListeners();
  }

  /// Refresh manual (dari tombol atau pull-to-refresh).
  Future<void> refresh({int pondId = 1}) => load(pondId: pondId);
}