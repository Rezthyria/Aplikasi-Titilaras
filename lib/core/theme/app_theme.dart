import 'package:flutter/material.dart';

import 'contrast.dart';

class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
}

class AppPalette {
  static const Color lightBackground = Color(0xFFF6EFE3);
  static const Color lightSurface = Color(0xFFFFF9EF);
  static const Color lightCard = Color(0xFFFFF7EA);
  static const Color lightText = Color(0xFF24170E);
  static const Color lightMutedText = Color(0xFF6B5A49);
  static const Color lightPrimary = Color(0xFF6F4322);
  static const Color lightSecondary = Color(0xFF9B5635);
  static const Color lightBorder = Color(0xFFD2B895);
  static const Color lightContainer = Color(0xFFEAD7B9);
  static const Color lightSoft = Color(0xFFF1E4D1);

  static const Color darkBackground = Color(0xFF120F0B);
  static const Color darkSurface = Color(0xFF1C1711);
  static const Color darkCard = Color(0xFF241C14);
  static const Color darkText = Color(0xFFF4EBDD);
  static const Color darkMutedText = Color(0xFFCDBDA7);
  static const Color darkPrimary = Color(0xFFC69A4A);
  static const Color darkSecondary = Color(0xFFB66A44);
  static const Color darkBorder = Color(0xFF5A4632);
  static const Color darkContainer = Color(0xFF4E341E);
  static const Color darkSoft = Color(0xFF33271C);
}

class AppTheme {
  // Penyesuaian visual dari folder contoh/ masih dependensi terbuka sesuai spec.
  static ThemeData light() {
    final scheme = const ColorScheme(
      brightness: Brightness.light,
      primary: AppPalette.lightPrimary,
      onPrimary: Colors.white,
      primaryContainer: AppPalette.lightContainer,
      onPrimaryContainer: Color(0xFF24170E),
      secondary: AppPalette.lightSecondary,
      onSecondary: Colors.white,
      secondaryContainer: Color(0xFFE8C6AE),
      onSecondaryContainer: Color(0xFF2B1308),
      error: Color(0xFFB3261E),
      onError: Colors.white,
      errorContainer: Color(0xFFFEE2E2),
      onErrorContainer: Color(0xFF7F1D1D),
      surface: AppPalette.lightSurface,
      onSurface: AppPalette.lightText,
      onSurfaceVariant: AppPalette.lightMutedText,
      surfaceContainerHighest: AppPalette.lightSoft,
      outline: AppPalette.lightBorder,
      outlineVariant: Color(0xFFE2E8F0),
      shadow: Colors.black,
    );
    return _base(scheme).copyWith(
      scaffoldBackgroundColor: AppPalette.lightBackground,
      cardColor: AppPalette.lightCard,
    );
  }

  static ThemeData dark() {
    final scheme = const ColorScheme(
      brightness: Brightness.dark,
      primary: AppPalette.darkPrimary,
      onPrimary: Color(0xFF271705),
      primaryContainer: AppPalette.darkContainer,
      onPrimaryContainer: AppPalette.darkText,
      secondary: AppPalette.darkSecondary,
      onSecondary: Color(0xFF120905),
      secondaryContainer: Color(0xFF61331F),
      onSecondaryContainer: Color(0xFFFFF1E7),
      error: Color(0xFFFFB4AB),
      onError: Color(0xFF690005),
      errorContainer: Color(0xFF7F1D1D),
      onErrorContainer: Color(0xFFFFE4E6),
      surface: AppPalette.darkSurface,
      onSurface: AppPalette.darkText,
      onSurfaceVariant: AppPalette.darkMutedText,
      surfaceContainerHighest: AppPalette.darkSoft,
      outline: AppPalette.darkBorder,
      outlineVariant: Color(0xFF243244),
      shadow: Colors.black,
    );
    return _base(scheme).copyWith(
      scaffoldBackgroundColor: AppPalette.darkBackground,
      cardColor: AppPalette.darkCard,
    );
  }

  static ThemeData _base(ColorScheme scheme) {
    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      textTheme: const TextTheme(
        headlineLarge: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
        headlineMedium: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
        titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(fontSize: 15, height: 1.35),
        bodyMedium: TextStyle(fontSize: 14, height: 1.35),
        labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        bodySmall: TextStyle(fontSize: 12, height: 1.3),
      ).apply(bodyColor: scheme.onSurface, displayColor: scheme.onSurface),
      cardTheme: CardThemeData(
        elevation: 2,
        shadowColor: scheme.shadow.withValues(alpha: 0.18),
        margin: EdgeInsets.zero,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(18)),
        ),
      ),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 2,
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: scheme.onSurface,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 3,
        backgroundColor: scheme.surface,
        indicatorColor: scheme.primary,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: scheme.onPrimary);
          }
          return IconThemeData(color: scheme.onSurfaceVariant);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: states.contains(WidgetState.selected)
                ? scheme.primary
                : scheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  static List<ContrastPair> contrastPairs() {
    return const [
      ContrastPair(AppPalette.lightText, AppPalette.lightBackground),
      ContrastPair(AppPalette.lightText, AppPalette.lightSurface),
      ContrastPair(AppPalette.lightMutedText, AppPalette.lightBackground),
      ContrastPair(Colors.white, AppPalette.lightPrimary),
      ContrastPair(Colors.white, AppPalette.lightSecondary),
      ContrastPair(AppPalette.darkText, AppPalette.darkBackground),
      ContrastPair(AppPalette.darkText, AppPalette.darkSurface),
      ContrastPair(AppPalette.darkMutedText, AppPalette.darkBackground),
      ContrastPair(Color(0xFF271705), AppPalette.darkPrimary),
      ContrastPair(Color(0xFF120905), AppPalette.darkSecondary),
    ];
  }
}
