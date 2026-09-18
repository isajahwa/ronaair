import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../core/constants/app_constants.dart';
import '../models/dashboard_data.dart';

/// Error khusus untuk API agar bisa dibedakan dari error lain.
class ApiException implements Exception {
  final String message;
  final bool isNetworkError;

  ApiException(this.message, {this.isNetworkError = false});

  @override
  String toString() => message;
}

/// Service yang menangani komunikasi HTTP ke backend Go.
class ApiService {
  final String baseUrl;
  final Duration timeout;

  ApiService({
    this.baseUrl = AppConstants.baseUrl,
    this.timeout = const Duration(seconds: 10),
  });

  // =========================================
  // DASHBOARD
  // =========================================

  /// GET /api/v1/dashboard?pond_id=X
  Future<DashboardData> getDashboard({int pondId = 1}) async {
    final uri = Uri.parse(
      '$baseUrl/api/${AppConstants.apiVersion}/dashboard'
      '?pond_id=$pondId',
    );

    try {
      final response = await http.get(uri).timeout(timeout);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return DashboardData.fromJson(json);
      } else {
        throw ApiException(
          'Server mengembalikan status ${response.statusCode}',
        );
      }
    } on SocketException {
      throw ApiException('Tidak dapat terhubung ke server',
          isNetworkError: true);
    } on HttpException {
      throw ApiException('Kesalahan koneksi HTTP',
          isNetworkError: true);
    } on FormatException {
      throw ApiException('Format data dari server tidak valid');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Terjadi kesalahan tidak terduga: $e');
    }
  }

  // =========================================
  // SENSOR
  // =========================================

  /// POST /api/v1/sensor — untuk testing manual dari aplikasi (opsional).
  Future<bool> postSensor({
    int pondId = 1,
    int? deviceId,
    double? temperature,
    double? ph,
    double? turbidity,
    double? estimatedDo,
  }) async {
    final uri = Uri.parse('$baseUrl/api/${AppConstants.apiVersion}/sensor');
    final body = jsonEncode({
      'pond_id': pondId,
      if (deviceId != null) 'device_id': deviceId,
      if (temperature != null) 'temperature': temperature,
      if (ph != null) 'ph': ph,
      if (turbidity != null) 'turbidity': turbidity,
      if (estimatedDo != null) 'estimated_do': estimatedDo,
    });

    try {
      final response = await http
          .post(uri,
              headers: {'Content-Type': 'application/json'},
              body: body)
          .timeout(timeout);
      return response.statusCode == 200;
    } on SocketException {
      throw ApiException('Tidak dapat terhubung ke server',
          isNetworkError: true);
    }
  }

  // =========================================
  // HISTORY
  // =========================================

  /// GET /api/v1/history?pond_id=X
  Future<List<Map<String, dynamic>>> getHistory({int pondId = 1}) async {
    final uri = Uri.parse(
      '$baseUrl/api/${AppConstants.apiVersion}/history'
      '?pond_id=$pondId',
    );

    try {
      final response = await http.get(uri).timeout(timeout);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final data = json['data'];
        if (data is List) {
          return data.cast<Map<String, dynamic>>();
        }
        return [];
      } else {
        throw ApiException(
          'Server mengembalikan status ${response.statusCode}',
        );
      }
    } on SocketException {
      throw ApiException('Tidak dapat terhubung ke server',
          isNetworkError: true);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Terjadi kesalahan: $e');
    }
  }
}