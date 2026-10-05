import 'package:flutter/material.dart';

/// Change the palette here to recolor the entire desktop app.
abstract final class AppColors {
  static const primary = Color(0xff3e7bdb);
  static const primaryDark = Color(0xff285eb3);
  static const primarySoft = Color(0xffe8f0ff);
  static const background = Color(0xfff5f7fb);
  static const surface = Color(0xffffffff);
  static const tabTrack = Color(0xffedf1f7);
  static const border = Color(0xffe1e6ef);
  static const borderStrong = Color(0xffe3e6eb);
  static const text = Color(0xff202635);
  static const textSecondary = Color(0xff697386);
  static const textMuted = Color(0xff4b5565);
  static const textSubtle = Color(0x8a000000);
  static const iconMuted = Color(0x73000000);
  static const onPrimary = Color(0xffffffff);
  static const archive = Color(0xffffb020);
  static const success = Color(0xff2e9d5b);
  static const danger = Color(0xffd64545);
  static const shadow = Color(0x10000000);
  static const transparent = Color(0x00000000);
}

abstract final class AppTheme {
  static ThemeData get light => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    fontFamily: 'Arial',
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: const ColorScheme.light(
      primary: AppColors.primary,
      onPrimary: AppColors.onPrimary,
      surface: AppColors.surface,
      onSurface: AppColors.text,
      outline: AppColors.border,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.surface,
      foregroundColor: AppColors.text,
      surfaceTintColor: AppColors.transparent,
    ),
    dividerColor: AppColors.border,
  );
}
