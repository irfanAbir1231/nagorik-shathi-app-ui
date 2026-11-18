import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;

/// Brand palette. Screens use these or the theme's colour scheme, never raw hex.
abstract final class AppColors {
  static const primary = Color(0xFF0B6E4F);
  static const primaryBright = Color(0xFF15946C);
  static const sun = Color(0xFFF4B942);
  static const ink = Color(0xFF13261F);

  /// Page background: a soft off-white so white cards stand out from it.
  static const canvas = Color(0xFFF5F7F6);

  static const success = Color(0xFF1B7F3B);
  static const warning = Color(0xFF9A6700);
  static const danger = Color(0xFFC62828);
}

/// Corner radii and spacing used across the app, so screens share one rhythm.
abstract final class AppRadius {
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 20.0;
  static const xl = 28.0;
}

abstract final class AppTheme {
  static const fontFamily = 'HindSiliguri';

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(seedColor: AppColors.primary).copyWith(
      primary: AppColors.primary,
      surface: Colors.white,
      error: AppColors.danger,
    );
    final base = ThemeData(useMaterial3: true, colorScheme: scheme, fontFamily: fontFamily);
    final text = base.textTheme.copyWith(
      headlineMedium: base.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
      headlineSmall: base.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
      titleLarge: base.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
      titleMedium: base.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      labelLarge: base.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
    );

    final roundedMd = RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md));
    final outline = scheme.outlineVariant;

    return base.copyWith(
      textTheme: text,
      scaffoldBackgroundColor: AppColors.canvas,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.canvas,
        foregroundColor: AppColors.ink,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0.5,
        shadowColor: Colors.black26,
        centerTitle: false,
        titleTextStyle: text.titleLarge?.copyWith(color: AppColors.ink),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(builders: {
        TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      }),
      cardTheme: CardThemeData(
        color: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: BorderSide(color: outline.withValues(alpha: 0.6)),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 52),
          shape: roundedMd,
          textStyle: text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 52),
          shape: roundedMd,
          side: BorderSide(color: outline),
          textStyle: text.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(textStyle: text.labelLarge?.copyWith(fontWeight: FontWeight.w700)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        shape: const StadiumBorder(),
        side: BorderSide(color: outline),
        backgroundColor: Colors.white,
        selectedColor: scheme.primaryContainer,
        labelStyle: text.labelLarge,
        showCheckmark: false,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl))),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.ink,
        actionTextColor: AppColors.sun,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
      ),
      bottomAppBarTheme: const BottomAppBarThemeData(
        color: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shadowColor: Colors.black26,
      ),
      dividerTheme: DividerThemeData(color: outline.withValues(alpha: 0.5), space: 1),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: scheme.primaryContainer,
        circularTrackColor: scheme.primaryContainer,
      ),
      checkboxTheme: CheckboxThemeData(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6))),
      tabBarTheme: TabBarThemeData(
        labelStyle: text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        unselectedLabelStyle: text.titleSmall,
        indicatorSize: TabBarIndicatorSize.label,
      ),
    );
  }
}
