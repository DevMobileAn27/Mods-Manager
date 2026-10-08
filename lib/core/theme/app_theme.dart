import 'package:flutter/material.dart';

/// Change the palette here to recolor the entire desktop app.
abstract final class AppColors {
  static const primary = Color(0xff5b86f7);
  static const primaryDark = Color(0xff8baaff);
  static const primarySoft = Color(0xff263c60);
  static const background = Color(0xff171d25);
  static const backgroundTop = Color(0xff2a3846);
  static const surface = Color(0xff222c37);
  static const surfaceRaised = Color(0xff2b3846);
  static const tabTrack = Color(0xff18212b);
  static const tabShadow = Color(0x2effffff);
  static const border = Color(0xff33414f);
  static const borderStrong = Color(0xff45586c);
  static const text = Color(0xfff1f4f8);
  static const textSecondary = Color(0xffb2c0cf);
  static const textMuted = Color(0xff9aabbc);
  static const textSubtle = Color(0xff9aabbc);
  static const iconMuted = Color(0xff8193a6);
  static const onPrimary = Color(0xffffffff);
  static const archive = Color(0xffe9b867);
  static const success = Color(0xff74d99d);
  static const danger = Color(0xffff7f87);
  static const shadow = Color(0x40000000);
  static const imageShade = Color(0xff121923);
  static const badgeBackground = Color(0x80000000);
  static const transparent = Color(0x00000000);
}

abstract final class AppTheme {
  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    fontFamily: 'Chakra Petch',
    fontFamilyFallback: const [
      'Microsoft YaHei',
      'PingFang SC',
      'Noto Sans CJK SC',
    ],
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.primary,
      onPrimary: AppColors.onPrimary,
      surface: AppColors.surface,
      onSurface: AppColors.text,
      onSurfaceVariant: AppColors.textSecondary,
      surfaceContainerHighest: AppColors.surfaceRaised,
      error: AppColors.danger,
      outline: AppColors.border,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.surface,
      foregroundColor: AppColors.text,
      surfaceTintColor: AppColors.transparent,
    ),
    dividerColor: AppColors.border,
    iconTheme: const IconThemeData(color: AppColors.textSecondary, size: 20),
    cardTheme: CardThemeData(
      color: AppColors.surface,
      surfaceTintColor: AppColors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
        side: const BorderSide(color: AppColors.border),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.surface,
      surfaceTintColor: AppColors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: AppColors.surfaceRaised,
      surfaceTintColor: AppColors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
        side: const BorderSide(color: AppColors.borderStrong),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        foregroundColor: AppColors.onPrimary,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
        textStyle: const TextStyle(
          fontFamily: 'Chakra Petch',
          fontWeight: FontWeight.w700,
          fontSize: 14,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.text,
        side: const BorderSide(color: AppColors.borderStrong),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      hintStyle: TextStyle(color: AppColors.textMuted),
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: AppColors.surfaceRaised,
      contentTextStyle: TextStyle(
        fontFamily: 'Chakra Petch',
        color: AppColors.text,
      ),
    ),
  );
}
