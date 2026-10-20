import 'package:flutter/material.dart';

abstract final class KcalColors {
  static const paper = Color(0xFFF3EDE4);
  static const card = Color(0xFFFFFBF7);
  static const ink = Color(0xFF2A2118);
  static const muted = Color(0xFF7A6A58);
  static const line = Color(0xFFE4D8C8);
  static const persimmon = Color(0xFFC4622D);
  static const persimmonDark = Color(0xFF8C3E16);
  static const sage = Color(0xFF3E6B58);
  static const amber = Color(0xFFB5812A);
  static const rose = Color(0xFFA34B4B);
  static const over = Color(0xFF9C2F2F);
  static const overBg = Color(0xFFF8E6E2);
  static const okBg = Color(0xFFE5F0E8);
}

ThemeData kcalTheme() {
  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: KcalColors.paper,
    colorScheme: ColorScheme.fromSeed(
      seedColor: KcalColors.persimmon,
      brightness: Brightness.light,
    ).copyWith(
      primary: KcalColors.persimmon,
      onPrimary: Colors.white,
      secondary: KcalColors.sage,
      surface: KcalColors.card,
      error: KcalColors.over,
    ),
  );

  return base.copyWith(
    textTheme: base.textTheme.apply(
      bodyColor: KcalColors.ink,
      displayColor: KcalColors.ink,
      fontFamilyFallback: const [
        'Microsoft YaHei',
        'PingFang SC',
        'Noto Sans SC',
        'Source Han Sans SC',
      ],
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: KcalColors.paper,
      foregroundColor: KcalColors.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: KcalColors.card,
      indicatorColor: const Color(0xFFF3D7C6),
      height: 68,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return TextStyle(
          fontSize: 12,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          color: selected ? KcalColors.persimmonDark : KcalColors.muted,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return IconThemeData(
          color: selected ? KcalColors.persimmonDark : KcalColors.muted,
        );
      }),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: KcalColors.persimmon,
      foregroundColor: Colors.white,
      elevation: 1,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: KcalColors.persimmon,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      labelStyle: const TextStyle(color: KcalColors.muted),
      helperStyle: const TextStyle(color: KcalColors.muted),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: KcalColors.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: KcalColors.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: KcalColors.persimmon, width: 1.4),
      ),
    ),
    dividerTheme: const DividerThemeData(color: KcalColors.line, space: 1),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: KcalColors.ink,
      contentTextStyle: const TextStyle(color: Colors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}
