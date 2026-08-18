import 'package:flutter/material.dart';

/// QIC brand palette — deep space navy with electric cyan + violet accents.
class AppColors {
  AppColors._();

  // Dark theme surfaces
  static const Color darkBg = Color(0xFF060A14);
  static const Color darkBgAlt = Color(0xFF0B1120);
  static const Color darkSurface = Color(0xFF10182B);

  // Light theme surfaces
  static const Color lightBg = Color(0xFFF3F6FC);
  static const Color lightBgAlt = Color(0xFFE7ECF6);
  static const Color lightSurface = Color(0xFFFFFFFF);

  // Brand accents (shared across themes)
  static const Color cyan = Color(0xFF22D3EE);
  static const Color cyanBright = Color(0xFF5EEBFF);
  static const Color violet = Color(0xFF7C5CFF);
  static const Color magenta = Color(0xFFE94BD1);

  // Status
  static const Color online = Color(0xFF35E28C);
  static const Color offline = Color(0xFFFF5C7A);
  static const Color warning = Color(0xFFFFC24B);

  static const List<Color> orbGradient = [cyan, violet, magenta];

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [cyan, violet],
  );

  static const LinearGradient speedGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [violet, cyan, cyanBright],
  );
}
