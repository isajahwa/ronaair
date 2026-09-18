import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Tipografi RonaAir memakai font Inter.
class AppTypography {
  AppTypography._();

  static TextTheme get textTheme => TextTheme(
        // Judul sangat besar, misal status risiko
        displayLarge: GoogleFonts.inter(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: AppColors.charcoal,
        ),
        // Judul halaman
        headlineMedium: GoogleFonts.inter(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: AppColors.charcoal,
        ),
        // Judul card / section
        titleMedium: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.charcoal,
        ),
        // Teks isi
        bodyMedium: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w400,
          color: AppColors.charcoal,
          height: 1.5,
        ),
        // Teks sekunder
        bodySmall: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          color: AppColors.midGray,
        ),
        // Label kecil
        labelMedium: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: AppColors.charcoal,
        ),
        // Caption (timestamp)
        labelSmall: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w400,
          color: AppColors.midGray,
        ),
      );
}