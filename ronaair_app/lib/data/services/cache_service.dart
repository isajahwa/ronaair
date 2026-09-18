import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/dashboard_data.dart';

/// Service untuk menyimpan data terakhir ke local storage.
/// Berguna saat offline atau gagal ambil data.
class CacheService {
  // Key untuk dashboard
  static const String _keyDashboard = 'cached_dashboard';
  static const String _keyTimestamp = 'cached_dashboard_timestamp';

  // Key untuk history
  static const String _keyHistory = 'cached_history';
  static const String _keyHistoryTimestamp = 'cached_history_timestamp';

  // =========================================
  // DASHBOARD CACHE
  // =========================================

  /// Simpan dashboard ke cache.
  Future<void> saveDashboard(DashboardData data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyDashboard, jsonEncode(data.toJson()));
    await prefs.setInt(
      _keyTimestamp,
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  /// Ambil dashboard dari cache (null kalau tidak ada).
  Future<DashboardData?> getDashboard() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyDashboard);
    if (raw == null) return null;

    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return DashboardData.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  /// Kapan terakhir kali cache dashboard disimpan.
  Future<DateTime?> getCachedAt() async {
    final prefs = await SharedPreferences.getInstance();
    final ms = prefs.getInt(_keyTimestamp);
    if (ms == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(ms);
  }

  // =========================================
  // HISTORY CACHE
  // =========================================

  /// Simpan riwayat ke cache.
  Future<void> saveHistory(List<Map<String, dynamic>> history) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyHistory, jsonEncode(history));
    await prefs.setInt(
      _keyHistoryTimestamp,
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  /// Ambil riwayat dari cache (null kalau tidak ada).
  Future<List<Map<String, dynamic>>?> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyHistory);
    if (raw == null) return null;

    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list.cast<Map<String, dynamic>>();
    } catch (_) {
      return null;
    }
  }

  /// Kapan terakhir kali cache history disimpan.
  Future<DateTime?> getHistoryCachedAt() async {
    final prefs = await SharedPreferences.getInstance();
    final ms = prefs.getInt(_keyHistoryTimestamp);
    if (ms == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(ms);
  }

  // =========================================
  // CLEAR
  // =========================================

  /// Hapus semua cache (untuk debugging).
  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyDashboard);
    await prefs.remove(_keyTimestamp);
    await prefs.remove(_keyHistory);
    await prefs.remove(_keyHistoryTimestamp);
  }
}