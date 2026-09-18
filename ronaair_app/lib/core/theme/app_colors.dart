import 'package:flutter/material.dart';

/// Palet warna RonaAir.
/// Semua warna aplikasi diambil dari sini agar konsisten.
class AppColors {
  AppColors._(); // Mencegah file ini di-instance

  // === Warna Utama (Brand) ===
  static const Color deepWater = Color(0xFF0B4F6C);
  static const Color aqua = Color(0xFF1B9AAA);
  static const Color freshMint = Color(0xFFA8E6CF);

  // === Warna Netral ===
  static const Color cloudWhite = Color(0xFFF7F9FA);
  static const Color softGray = Color(0xFFE4E8EB);
  static const Color midGray = Color(0xFF8A9199);
  static const Color charcoal = Color(0xFF1F2933);

  // === Warna Risiko ===
  static const Color riskNormal = Color(0xFF2E9E5B);
  static const Color riskWaspada = Color(0xFFE8A400);
  static const Color riskSiaga = Color(0xFFE86A17);
  static const Color riskDarurat = Color(0xFFC7302B);

  // === Warna Background Lembut (untuk card risiko) ===
  static const Color riskNormalBg = Color(0xFFE6F4EA);
  static const Color riskWaspadaBg = Color(0xFFFDF3D9);
  static const Color riskSiagaBg = Color(0xFFFCE7D6);
  static const Color riskDaruratBg = Color(0xFFF7DEDC);

  // === Warna Status Sistem ===
  static const Color statusOnline = Color(0xFF2E9E5B);
  static const Color statusOffline = Color(0xFF8A9199);
  static const Color statusError = Color(0xFFC7302B);
  static const Color statusWarning = Color(0xFFE8A400);
  static const Color statusInfo = Color(0xFF1B9AAA);
}