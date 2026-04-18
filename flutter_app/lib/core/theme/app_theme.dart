import 'package:flutter/material.dart';

// ============================================================
// [테마 설정] app_theme.dart
// 앱 전체 시각 스타일 정의 — 라이트/다크 모드 모두 지원.
//
// 구조:
//   AppColors   — 의미 단위 색상 토큰 (라이트/다크 분리)
//   AppSpacing  — 여백/간격 단위
//   AppRadii    — 둥근 모서리 반경
//   AppTheme    — ThemeData (lightTheme, darkTheme) + 레거시 상수
//
// 레거시 호환:
//   기존 코드가 `AppTheme.primaryColor`, `AppTheme.backgroundColor`,
//   `AppTheme.borderRadiusMedium` 등을 참조 중 → 유지.
// ============================================================

/// 의미 단위 색상 토큰. 라이트/다크 팔레트를 동일 이름으로 노출.
class AppColors {
  AppColors._();

  // Brand
  static const Color brand = Color(0xFF3B82F6); // Blue — primary/accent
  static const Color brandDark = Color(0xFF60A5FA); // Lighter blue for dark mode

  // Semantic
  static const Color income = Color(0xFF3B82F6);
  static const Color expense = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color success = Color(0xFF10B981);

  // Light mode surfaces
  static const Color lightBackground = Color(0xFFF8F8FC);
  static const Color lightSurface = Colors.white;
  static const Color lightSurfaceVariant = Color(0xFFF1F3F9);
  static const Color lightBorder = Color(0xFFE5E7EB);
  static const Color lightOnSurface = Color(0xDE000000); // black87
  static const Color lightOnSurfaceMuted = Color(0x8A000000); // black54

  // Dark mode surfaces
  static const Color darkBackground = Color(0xFF0F1115);
  static const Color darkSurface = Color(0xFF1A1D23);
  static const Color darkSurfaceVariant = Color(0xFF242932);
  static const Color darkBorder = Color(0xFF2F3641);
  static const Color darkOnSurface = Color(0xFFE6E8EE);
  static const Color darkOnSurfaceMuted = Color(0xFF9BA3B4);
}

/// 여백/간격 단위 (4dp 그리드).
class AppSpacing {
  AppSpacing._();
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
}

/// 둥근 모서리 반경.
class AppRadii {
  AppRadii._();
  static const double sm = 8;
  static const double md = 12;
  static const double card = 16;
  static const double lg = 20;
  static const double pill = 999;
}

class AppTheme {
  AppTheme._();

  // ─── Legacy constants (기존 화면 호환용) ─────────────────────
  static const Color backgroundColor = AppColors.lightBackground;
  static const Color expenseColor = AppColors.expense;
  static const Color incomeColor = AppColors.income;
  static const Color primaryColor = AppColors.brand;
  static const Color errorColor = AppColors.expense;

  static const double borderRadiusSmall = AppRadii.sm;
  static const double borderRadiusMedium = AppRadii.md;
  static const double borderRadiusCards = AppRadii.card;
  static const double borderRadiusLarge = AppRadii.lg;

  // ─── TextTheme factory ───────────────────────────────────────
  static TextTheme _textTheme(Color onSurface, Color onSurfaceMuted) {
    return TextTheme(
      headlineLarge: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: onSurface,
      ),
      headlineMedium: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: onSurface,
      ),
      headlineSmall: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: onSurface,
      ),
      titleLarge: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: onSurface,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: onSurface,
      ),
      bodyLarge: TextStyle(fontSize: 16, color: onSurface),
      bodyMedium: TextStyle(fontSize: 14, color: onSurface),
      bodySmall: TextStyle(fontSize: 12, color: onSurfaceMuted),
    );
  }

  // ─── Light theme ─────────────────────────────────────────────
  static ThemeData lightTheme = _buildTheme(
    brightness: Brightness.light,
    background: AppColors.lightBackground,
    surface: AppColors.lightSurface,
    surfaceVariant: AppColors.lightSurfaceVariant,
    border: AppColors.lightBorder,
    onSurface: AppColors.lightOnSurface,
    onSurfaceMuted: AppColors.lightOnSurfaceMuted,
    primary: AppColors.brand,
  );

  // ─── Dark theme ──────────────────────────────────────────────
  static ThemeData darkTheme = _buildTheme(
    brightness: Brightness.dark,
    background: AppColors.darkBackground,
    surface: AppColors.darkSurface,
    surfaceVariant: AppColors.darkSurfaceVariant,
    border: AppColors.darkBorder,
    onSurface: AppColors.darkOnSurface,
    onSurfaceMuted: AppColors.darkOnSurfaceMuted,
    primary: AppColors.brandDark,
  );

  // ─── Shared theme builder ────────────────────────────────────
  static ThemeData _buildTheme({
    required Brightness brightness,
    required Color background,
    required Color surface,
    required Color surfaceVariant,
    required Color border,
    required Color onSurface,
    required Color onSurfaceMuted,
    required Color primary,
  }) {
    final isDark = brightness == Brightness.dark;
    final textTheme = _textTheme(onSurface, onSurfaceMuted);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      primaryColor: primary,
      scaffoldBackgroundColor: background,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: primary,
        onPrimary: Colors.white,
        secondary: AppColors.income,
        onSecondary: Colors.white,
        error: AppColors.expense,
        onError: Colors.white,
        surface: surface,
        onSurface: onSurface,
        surfaceContainerHighest: surfaceVariant,
        outline: border,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? surface : primary,
        foregroundColor: isDark ? onSurface : Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: isDark ? onSurface : Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(color: isDark ? onSurface : Colors.white),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: isDark ? 0 : 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.card),
          side: isDark
              ? BorderSide(color: border, width: 0.5)
              : BorderSide.none,
        ),
      ),
      dividerTheme: DividerThemeData(color: border, thickness: 1),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? surfaceVariant : background,
        hintStyle: TextStyle(color: onSurfaceMuted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: BorderSide(color: primary),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: const BorderSide(color: AppColors.expense),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.md),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.md,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: BorderSide(color: primary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.md),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.md,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: primary),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        indicatorColor: primary.withValues(alpha: 0.15),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            color: selected ? primary : onSurfaceMuted,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(color: selected ? primary : onSurfaceMuted);
        }),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadii.lg),
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark ? surfaceVariant : const Color(0xFF323232),
        contentTextStyle: const TextStyle(color: Colors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
        ),
      ),
      iconTheme: IconThemeData(color: onSurfaceMuted),
      textTheme: textTheme,
    );
  }
}
