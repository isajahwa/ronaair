import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Empat tingkat risiko RonaAir (sesuai master concept).
enum RiskLevel { normal, waspada, siaga, darurat }

extension RiskLevelX on RiskLevel {
  /// Label teks yang ditampilkan ke pengguna.
  String get label {
    switch (this) {
      case RiskLevel.normal:
        return 'NORMAL';
      case RiskLevel.waspada:
        return 'WASPADA';
      case RiskLevel.siaga:
        return 'SIAGA';
      case RiskLevel.darurat:
        return 'DARURAT';
    }
  }

  /// Warna utama status.
  Color get color {
    switch (this) {
      case RiskLevel.normal:
        return AppColors.riskNormal;
      case RiskLevel.waspada:
        return AppColors.riskWaspada;
      case RiskLevel.siaga:
        return AppColors.riskSiaga;
      case RiskLevel.darurat:
        return AppColors.riskDarurat;
    }
  }

  /// Warna background lembut untuk card.
  Color get backgroundColor {
    switch (this) {
      case RiskLevel.normal:
        return AppColors.riskNormalBg;
      case RiskLevel.waspada:
        return AppColors.riskWaspadaBg;
      case RiskLevel.siaga:
        return AppColors.riskSiagaBg;
      case RiskLevel.darurat:
        return AppColors.riskDaruratBg;
    }
  }

  /// Deskripsi singkat untuk pengguna.
  String get description {
    switch (this) {
      case RiskLevel.normal:
        return 'Kondisi kolam relatif stabil.';
      case RiskLevel.waspada:
        return 'Ada perubahan yang perlu dipantau.';
      case RiskLevel.siaga:
        return 'Kondisi menunjukkan peningkatan risiko.';
      case RiskLevel.darurat:
        return 'Kondisi berisiko tinggi, perlu tindakan cepat.';
    }
  }

  /// Konversi dari string API ke enum.
  static RiskLevel fromString(String value) {
    switch (value.toUpperCase()) {
      case 'NORMAL':
        return RiskLevel.normal;
      case 'WASPADA':
        return RiskLevel.waspada;
      case 'SIAGA':
        return RiskLevel.siaga;
      case 'DARURAT':
        return RiskLevel.darurat;
      default:
        return RiskLevel.normal;
    }
  }
}