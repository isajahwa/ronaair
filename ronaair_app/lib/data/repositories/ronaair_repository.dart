import '../models/dashboard_data.dart';
import '../services/api_service.dart';
import '../services/cache_service.dart';

/// Hasil dari repository: data + status sumbernya.
class RepoResult {
  final DashboardData? data;
  final bool isFromCache;
  final DateTime? cachedAt;
  final String? errorMessage;

  RepoResult({
    this.data,
    this.isFromCache = false,
    this.cachedAt,
    this.errorMessage,
  });

  bool get hasData => data != null;
  bool get isOffline => isFromCache;
}

/// Repository yang menggabungkan API + Cache.
class RonaAirRepository {
  final ApiService api;
  final CacheService cache;

  RonaAirRepository({
    ApiService? api,
    CacheService? cache,
  })  : api = api ?? ApiService(),
        cache = cache ?? CacheService();

  // =========================================
  // DASHBOARD
  // =========================================

  /// Ambil dashboard dengan strategi:
  /// 1. Coba dari API (online-first).
  /// 2. Kalau gagal → pakai cache.
  Future<RepoResult> getDashboard({int pondId = 1}) async {
    try {
      final data = await api.getDashboard(pondId: pondId);

      // Simpan ke cache untuk dipakai saat offline.
      await cache.saveDashboard(data);

      return RepoResult(
        data: data,
        isFromCache: false,
        cachedAt: DateTime.now(),
      );
    } catch (e) {
      // Gagal ambil dari API → coba cache.
      final cached = await cache.getDashboard();
      final cachedAt = await cache.getCachedAt();

      if (cached != null) {
        return RepoResult(
          data: cached,
          isFromCache: true,
          cachedAt: cachedAt,
          errorMessage: 'Offline — menampilkan data terakhir '
              '(${_formatCachedAt(cachedAt)})',
        );
      }

      // Tidak ada API, tidak ada cache.
      return RepoResult(
        errorMessage: e.toString(),
      );
    }
  }

  // =========================================
  // HISTORY
  // =========================================

  /// Ambil riwayat pemeriksaan (API → cache).
  ///
  /// Catatan: Method ini khusus untuk history. Kita tidak pakai
  /// DashboardData. Hanya return status (berhasil/gagal/offline),
  /// sedangkan data history diambil langsung dari cache/API
  /// oleh HistoryProvider.
  Future<RepoResult> getHistory({int pondId = 1}) async {
    try {
      final list = await api.getHistory(pondId: pondId);
      await cache.saveHistory(list);

      return RepoResult(
        data: null,
        isFromCache: false,
        cachedAt: DateTime.now(),
      );
    } catch (e) {
      final cached = await cache.getHistory();
      final cachedAt = await cache.getHistoryCachedAt();

      if (cached != null) {
        return RepoResult(
          data: null,
          isFromCache: true,
          cachedAt: cachedAt,
          errorMessage: 'Offline — menampilkan riwayat terakhir '
              '(${_formatCachedAt(cachedAt)})',
        );
      }

      return RepoResult(errorMessage: e.toString());
    }
  }

  // =========================================
  // HELPERS
  // =========================================

  /// Format waktu cache jadi teks yang manusiawi.
  /// Contoh: "baru saja", "5 menit lalu", "2 jam lalu", "3 hari lalu"
  String _formatCachedAt(DateTime? time) {
    if (time == null) return 'waktu tidak diketahui';

    final diff = DateTime.now().difference(time);

    if (diff.inMinutes < 1) return 'baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    return '${diff.inDays} hari lalu';
  }

  // =========================================
  // CLEAR
  // =========================================

  /// Hapus cache (debugging).
  Future<void> clearCache() => cache.clear();
}