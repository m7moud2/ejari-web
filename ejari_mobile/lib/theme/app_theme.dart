import 'package:flutter/material.dart';

/// هوية إيجاري البصرية للنسخة الأولى.
///
/// القاعدة هنا مقصودة: ٥ ألوان فقط داخل التطبيق، بدون أسود، علشان التجربة
/// تكون هادئة وموحدة وسهلة على العين.
class AppTheme {
  static const Color primaryColor = Color(0xFF4F7D70);
  static const Color accentColor = Color(0xFFD8C3A5);
  static const Color backgroundColor = Color(0xFFF6F1E8);
  static const Color surfaceColor = Color(0xFFFFFCF7);
  static const Color textPrimary = Color(0xFF32433D);
  static const Color textSecondary = Color(0xFF5D746C);
  static const Color errorColor = Color(0xFFA66A60);
  static const Color borderColor = Color(0xFFD8C3A5);

  static Color glassColor(BuildContext context) =>
      surfaceColor.withOpacity(0.92);

  static TextTheme _textTheme() {
    final base = ThemeData.light().textTheme;

    return base
        .copyWith(
          bodyLarge: const TextStyle(
            height: 1.6,
            fontSize: 16,
            color: textPrimary,
            letterSpacing: 0.1,
          ),
          bodyMedium: const TextStyle(
            height: 1.6,
            fontSize: 14,
            color: textPrimary,
            letterSpacing: 0.1,
          ),
          bodySmall: const TextStyle(
            height: 1.5,
            fontSize: 12,
            color: textSecondary,
            letterSpacing: 0.1,
          ),
          titleLarge: const TextStyle(
            height: 1.35,
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: textPrimary,
          ),
          titleMedium: const TextStyle(
            height: 1.4,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: textPrimary,
          ),
          titleSmall: const TextStyle(
            height: 1.4,
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: textPrimary,
          ),
        )
        .apply(
          fontFamily: 'Tajawal',
          bodyColor: textPrimary,
          displayColor: textPrimary,
        );
  }

  static ThemeData _buildLightTheme() {
    const scheme = ColorScheme(
      brightness: Brightness.light,
      primary: primaryColor,
      onPrimary: Colors.white,
      secondary: accentColor,
      onSecondary: textPrimary,
      error: errorColor,
      onError: Colors.white,
      surface: surfaceColor,
      onSurface: textPrimary,
    );

    final roundedCard = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(22),
      side: BorderSide(color: borderColor.withOpacity(0.45), width: 1),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: 'Tajawal',
      colorScheme: scheme,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,
      canvasColor: backgroundColor,
      dividerColor: borderColor.withOpacity(0.5),
      textTheme: _textTheme(),
      appBarTheme: const AppBarTheme(
        backgroundColor: backgroundColor,
        foregroundColor: textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          fontFamily: 'Tajawal',
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
        iconTheme: IconThemeData(color: textPrimary),
      ),
      cardTheme: CardTheme(
        color: surfaceColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: roundedCard,
        margin: const EdgeInsets.only(bottom: 16),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(48, 56),
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          disabledBackgroundColor: primaryColor.withOpacity(0.35),
          disabledForegroundColor: Colors.white.withOpacity(0.75),
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          textStyle: const TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 56),
          foregroundColor: primaryColor,
          side: const BorderSide(color: primaryColor, width: 1.4),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          textStyle: const TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          textStyle: const TextStyle(
            fontFamily: 'Tajawal',
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceColor,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        hintStyle: TextStyle(color: textPrimary.withOpacity(0.48)),
        labelStyle: const TextStyle(color: textSecondary),
        prefixIconColor: textSecondary,
        suffixIconColor: textSecondary,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: borderColor.withOpacity(0.65)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: borderColor.withOpacity(0.65)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primaryColor, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: errorColor),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: errorColor, width: 1.8),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surfaceColor,
        indicatorColor: accentColor.withOpacity(0.45),
        elevation: 0,
        labelTextStyle: WidgetStateProperty.resolveWith((states) => TextStyle(
              fontFamily: 'Tajawal',
              fontWeight: states.contains(WidgetState.selected)
                  ? FontWeight.w800
                  : FontWeight.w600,
              fontSize: 12,
              color: states.contains(WidgetState.selected)
                  ? primaryColor
                  : textSecondary,
            )),
        iconTheme: WidgetStateProperty.resolveWith((states) => IconThemeData(
              color: states.contains(WidgetState.selected)
                  ? primaryColor
                  : textSecondary,
            )),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surfaceColor,
        selectedItemColor: primaryColor,
        unselectedItemColor: textSecondary,
        selectedLabelStyle: TextStyle(
          fontFamily: 'Tajawal',
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
        unselectedLabelStyle: TextStyle(
          fontFamily: 'Tajawal',
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        elevation: 0,
        type: BottomNavigationBarType.fixed,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceColor,
        selectedColor: accentColor.withOpacity(0.55),
        labelStyle:
            const TextStyle(color: textPrimary, fontWeight: FontWeight.w600),
        side: BorderSide(color: borderColor.withOpacity(0.65)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: primaryColor,
        contentTextStyle:
            const TextStyle(color: Colors.white, fontFamily: 'Tajawal'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      dividerTheme: DividerThemeData(
        color: borderColor.withOpacity(0.5),
        thickness: 1,
        space: 1,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected) ? primaryColor : accentColor),
        trackColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected)
                ? primaryColor.withOpacity(0.28)
                : accentColor.withOpacity(0.35)),
      ),
    );
  }

  static ThemeData get lightTheme => _buildLightTheme();

  /// لا نعرض مظهرًا داكنًا في النسخة الأولى حتى لا نكسر الهوية الهادئة.
  static ThemeData get darkTheme => lightTheme;
}
