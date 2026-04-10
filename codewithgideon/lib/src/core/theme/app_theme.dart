import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const deepBlue = Color(0xFF0F2B5B);
  static const deepBlueLight = Color(0xFF224A88);
  static const deepBlueDark = Color(0xFF08152E);
  static const teal = Color(0xFF1698A0);
  static const tealLight = Color(0xFF73D5D2);
  static const tealDark = Color(0xFF136B72);
  static const orange = Color(0xFFFF7A45);
  static const orangeLight = Color(0xFFFFA37A);
  static const background = Color(0xFFF4F7FB);
  static const surface = Colors.white;
  static const foreground = Color(0xFF10203E);
  static const muted = Color(0xFFEAF0F6);
  static const mutedForeground = Color(0xFF61708A);
  static const border = Color(0x14000000);
  static const success = Color(0xFF10B981);
  static const warning = orange;
  static const danger = Color(0xFFD4183D);
  static const purple = Color(0xFF7C3AED);
  static const shellBackground = Color(0xFFDDE6F1);
  static const darkBackground = Color(0xFF09111F);
  static const darkSurface = Color(0xFF111B2D);
  static const darkForeground = Color(0xFFE7EEF8);
  static const darkMuted = Color(0xFF172337);
  static const darkMutedForeground = Color(0xFF95A3BC);
  static const darkBorder = Color(0x22FFFFFF);
}

class AppGradients {
  static const primary = LinearGradient(
    colors: [AppColors.deepBlue, AppColors.deepBlueLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const premium = LinearGradient(
    colors: [Color(0xFFF5F8FD), Color(0xFFE8EFF8), Color(0xFFF6FBFF)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const accent = LinearGradient(
    colors: [AppColors.teal, AppColors.tealLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const danger = LinearGradient(
    colors: [AppColors.orange, AppColors.orangeLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class AppShadows {
  static List<BoxShadow> get card => [
    BoxShadow(
      color: AppColors.deepBlue.withValues(alpha: 0.08),
      blurRadius: 28,
      offset: const Offset(0, 10),
    ),
  ];

  static List<BoxShadow> get premium => [
    BoxShadow(
      color: AppColors.deepBlue.withValues(alpha: 0.16),
      blurRadius: 40,
      offset: const Offset(0, 16),
    ),
    BoxShadow(
      color: AppColors.teal.withValues(alpha: 0.08),
      blurRadius: 28,
      offset: const Offset(0, 10),
    ),
  ];
}

class AppTheme {
  static ThemeData get lightTheme {
    final base = ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.background,
      useMaterial3: true,
      colorScheme: const ColorScheme.light(
        primary: AppColors.deepBlue,
        secondary: AppColors.teal,
        surface: AppColors.surface,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppColors.foreground,
        error: AppColors.danger,
      ),
    );

    final textTheme = GoogleFonts.manropeTextTheme(base.textTheme)
        .copyWith(
          displayLarge: GoogleFonts.sora(
            fontSize: 40,
            fontWeight: FontWeight.w700,
            color: AppColors.foreground,
            height: 1.02,
            letterSpacing: -1.2,
          ),
          displayMedium: GoogleFonts.sora(
            fontSize: 34,
            fontWeight: FontWeight.w700,
            color: AppColors.foreground,
            height: 1.04,
            letterSpacing: -0.9,
          ),
          displaySmall: GoogleFonts.sora(
            fontSize: 29,
            fontWeight: FontWeight.w700,
            color: AppColors.foreground,
            height: 1.08,
            letterSpacing: -0.8,
          ),
          headlineLarge: GoogleFonts.sora(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: AppColors.foreground,
            height: 1.12,
            letterSpacing: -0.6,
          ),
          headlineMedium: GoogleFonts.sora(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppColors.foreground,
            height: 1.14,
            letterSpacing: -0.4,
          ),
          headlineSmall: GoogleFonts.sora(
            fontSize: 19,
            fontWeight: FontWeight.w700,
            color: AppColors.foreground,
            height: 1.16,
            letterSpacing: -0.3,
          ),
          titleLarge: GoogleFonts.manrope(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.foreground,
            height: 1.22,
            letterSpacing: -0.2,
          ),
          titleMedium: GoogleFonts.manrope(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.foreground,
            height: 1.24,
          ),
          titleSmall: GoogleFonts.manrope(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.foreground,
            height: 1.25,
          ),
          bodyLarge: GoogleFonts.manrope(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: AppColors.foreground,
            height: 1.52,
          ),
          bodyMedium: GoogleFonts.manrope(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.foreground,
            height: 1.55,
          ),
          bodySmall: GoogleFonts.manrope(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.mutedForeground,
            height: 1.5,
          ),
          labelLarge: GoogleFonts.manrope(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.1,
          ),
          labelMedium: GoogleFonts.manrope(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.1,
          ),
          labelSmall: GoogleFonts.manrope(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        );

    return base.copyWith(
      textTheme: textTheme,
      cardColor: Colors.white,
      dividerColor: AppColors.border,
      canvasColor: AppColors.background,
      splashFactory: NoSplash.splashFactory,
      appBarTheme: const AppBarTheme(backgroundColor: Colors.transparent),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.88),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: BorderSide(
            color: AppColors.deepBlue.withValues(alpha: 0.08),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: const BorderSide(color: AppColors.teal, width: 1.6),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    final light = lightTheme;
    final textTheme = light.textTheme;

    return light.copyWith(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.darkBackground,
      canvasColor: AppColors.darkBackground,
      cardColor: const Color(0xFF121E31),
      dividerColor: AppColors.darkBorder,
      colorScheme: light.colorScheme.copyWith(
        brightness: Brightness.dark,
        primary: const Color(0xFF87A8D9),
        secondary: const Color(0xFF54B8BC),
        surface: AppColors.darkSurface,
        onSurface: AppColors.darkForeground,
        onPrimary: AppColors.deepBlueDark,
        onSecondary: AppColors.deepBlueDark,
      ),
      textTheme: textTheme.apply(
        bodyColor: AppColors.darkForeground,
        displayColor: AppColors.darkForeground,
      ),
      inputDecorationTheme: light.inputDecorationTheme.copyWith(
        fillColor: Colors.white.withValues(alpha: 0.06),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: const BorderSide(color: AppColors.tealLight, width: 1.4),
        ),
      ),
    );
  }

  static BorderRadius get radiusLg => BorderRadius.circular(24);
  static BorderRadius get radiusXl => BorderRadius.circular(32);
}

BoxDecoration glassDecoration({
  BorderRadius? borderRadius,
  Color color = Colors.white,
}) {
  return BoxDecoration(
    color: color.withValues(alpha: 0.78),
    borderRadius: borderRadius ?? BorderRadius.circular(24),
    border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
  );
}

BackdropFilter glassBlur({required Widget child}) {
  return BackdropFilter(
    filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
    child: child,
  );
}
