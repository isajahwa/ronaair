/// Konstanta umum RonaAir.
class AppConstants {
  AppConstants._();

  static const String appName = 'RonaAir';
  static const String appTagline = 'Sistem Peringatan Dini Kualitas Air Kolam';

  // Base URL backend Go.
  // PENTING: saat development di emulator Android, gunakan 10.0.2.2
  // karena localhost di emulator = emulator sendiri.
  // Contoh: 'http://10.0.2.2:8080'
  // Untuk device fisik, ganti dengan IP laptop di jaringan lokal.
  static const String baseUrl = 'http://192.168.56.1:8080';

  // Versi API
  static const String apiVersion = 'v1';

  // Status risiko (sesuai master concept)
  static const String riskNormal = 'NORMAL';
  static const String riskWaspada = 'WASPADA';
  static const String riskSiaga = 'SIAGA';
  static const String riskDarurat = 'DARURAT';
}