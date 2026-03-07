import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static final ColorScheme _scheme = ColorScheme(
    brightness: Brightness.dark,
    primary: AppColors.goldBright,
    onPrimary: AppColors.ink,
    primaryContainer: AppColors.goldDim,
    onPrimaryContainer: AppColors.goldBright,
    secondary: const Color(0xFF90CAF9),
    onSecondary: AppColors.ink,
    secondaryContainer: const Color(0xFF1A3A5C),
    onSecondaryContainer: const Color(0xFFBBDEFB),
    tertiary: AppColors.purple,
    onTertiary: AppColors.ink,
    tertiaryContainer: AppColors.purpleDim,
    onTertiaryContainer: AppColors.purpleBright,
    error: AppColors.danger,
    onError: Colors.white,
    errorContainer: AppColors.dangerDim,
    onErrorContainer: AppColors.danger,
    surface: AppColors.ink,
    onSurface: AppColors.textPrimary,
    onSurfaceVariant: AppColors.textSecondary,
    surfaceContainerHighest: AppColors.inkCard,
    surfaceContainerHigh: const Color(0xFF1F3044),
    surfaceContainerLow: AppColors.inkLight,
    surfaceContainer: const Color(0xFF172336),
    outline: AppColors.border,
    outlineVariant: AppColors.borderSubtle,
    inverseSurface: AppColors.textPrimary,
    onInverseSurface: AppColors.ink,
    shadow: Colors.black,
    scrim: Colors.black,
  );

  static ThemeData get lightTheme => _buildTheme();

  @Deprecated('Use lightTheme instead')
  static ThemeData get darkTheme => lightTheme;

  static ThemeData _buildTheme() {
    final base = ThemeData(
      colorScheme: _scheme,
      useMaterial3: true,
      brightness: Brightness.dark,
    );

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.ink,
      appBarTheme: AppBarTheme(
        centerTitle: true,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: AppColors.inkCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: AppColors.borderSubtle.withAlpha(80)),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: const StadiumBorder(),
        backgroundColor: AppColors.inkLight,
        selectedColor: AppColors.goldDim,
        labelStyle: const TextStyle(color: AppColors.textPrimary),
        side: BorderSide(color: AppColors.borderSubtle),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.inkSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: AppColors.gold.withAlpha(40)),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppColors.inkSurface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.inkCard,
        contentTextStyle: const TextStyle(color: AppColors.textPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: AppColors.borderSubtle),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 4,
        backgroundColor: AppColors.gold,
        foregroundColor: AppColors.ink,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.gold,
          foregroundColor: AppColors.ink,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.goldBright,
          side: BorderSide(color: AppColors.gold.withAlpha(100)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.goldBright,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.inkLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.borderSubtle),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.borderSubtle),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.gold, width: 1.5),
        ),
        labelStyle: const TextStyle(color: AppColors.textTertiary),
        hintStyle: const TextStyle(color: AppColors.textMuted),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: AppColors.inkSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppColors.borderSubtle),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 0.5,
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.inkLight,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: AppColors.borderSubtle),
          ),
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: AppColors.goldBright,
        unselectedLabelColor: AppColors.textMuted,
        indicatorColor: AppColors.gold,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.gold,
      ),
    );
  }
}
