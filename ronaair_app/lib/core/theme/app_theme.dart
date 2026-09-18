import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

/// Tema utama RonaAir (light mode).
class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.cloudWhite,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.aqua,
          primary: AppColors.deepWater,
          secondary: AppColors.aqua,
          surface: AppColors.cloudWhite,
        ),
        textTheme: AppTypography.textTheme,

        // AppBar
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.cloudWhite,
          foregroundColor: AppColors.charcoal,
          elevation: 0,
          centerTitle: false,
        ),

        // Tombol utama
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.aqua,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            textStyle: AppTypography.textTheme.titleMedium,
          ),
        ),

        // Card ← INI YANG DIPERBAIKI
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          ),
        ),

        // Input
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.all(AppSpacing.lg),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            borderSide: const BorderSide(color: AppColors.softGray),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            borderSide: const BorderSide(color: AppColors.softGray),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            borderSide: const BorderSide(color: AppColors.aqua, width: 2),
          ),
        ),
      );
}