import 'package:flutter/foundation.dart';
import '../../data/services/api_service.dart';
import '../../data/services/cache_service.dart';

class HistoryProvider extends ChangeNotifier {
  final ApiService _api;
  final CacheService _cache;

  HistoryProvider({ApiService? api, CacheService? cache})
      : _api = api ?? ApiService(),
        _cache = cache ?? CacheService();

  List<Map<String, dynamic>> _items = [];
  bool _isLoading = false;
  bool _isOffline = false;
  DateTime? _cachedAt;
  String? _error;

  List<Map<String, dynamic>> get items => _items;
  bool get isLoading => _isLoading;
  bool get isOffline => _isOffline;
  DateTime? get cachedAt => _cachedAt;
  String? get error => _error;

  Future<void> load({int pondId = 1}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final list = await _api.getHistory(pondId: pondId);
      await _cache.saveHistory(list);
      _items = list;
      _isOffline = false;
      _cachedAt = DateTime.now();
    } catch (e) {
      final cached = await _cache.getHistory();
      if (cached != null) {
        _items = cached;
        _isOffline = true;
        _cachedAt = await _cache.getHistoryCachedAt();
      } else {
        _error = 'Tidak dapat memuat riwayat.';
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> refresh({int pondId = 1}) => load(pondId: pondId);
}