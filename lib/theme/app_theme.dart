import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData dark() {
    final base = ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.darkBg,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.cyan,
        secondary: AppColors.violet,
        surface: AppColors.darkSurface,
        onSurface: Colors.white,
      ),
      fontFamily: 'LiberationSans',
    );
    return base.copyWith(
      textTheme: base.textTheme.apply(
        bodyColor: Colors.white.withValues(alpha: 0.92),
        displayColor: Colors.white,
      ),
      splashFactory: InkSparkle.splashFactory,
    );
  }

  static ThemeData light() {
    final base = ThemeData(
      brightness: Brightness.light,
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.lightBg,
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF0EA5C4),
        secondary: AppColors.violet,
        surface: AppColors.lightSurface,
        onSurface: Color(0xFF10182B),
      ),
      fontFamily: 'LiberationSans',
    );
    return base.copyWith(
      textTheme: base.textTheme.apply(
        bodyColor: const Color(0xFF10182B).withValues(alpha: 0.92),
        displayColor: const Color(0xFF10182B),
      ),
    );
  }
}
