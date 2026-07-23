import 'package:flutter/material.dart';

/// هوية إيجاري البصرية (التصميم الحديث).
class AppTheme {
  // الألوان الأساسية الجديدة من التصميم المرفق
  static const Color primaryColor =
      Color(0xFF0F3A30); // الأخضر الداكن جداً (لون العلامة التجارية)
  static const Color primaryLight =
      Color(0xFF1B594B); // أخضر أفتح قليلاً للأزرار والحالات
  static const Color accentColor =
      Color(0xFFB58D3D); // الذهبي / الأصفر المائل للذهبي

  // ألوان الخلفيات والأسطح
  static const Color backgroundColor =
      Color(0xFFF8F9FA); // رمادي فاتح جداً مريح للعين
  static const Color surfaceColor = Color(0xFFFFFFFF); // أبيض ناصع للكروت

  // ألوان النصوص
  static const Color textPrimary =
      Color(0xFF1E293B); // أسود مائل للرمادي الداكن للنصوص الأساسية
  static const Color textSecondary = Color(0xFF64748B); // رمادي للنصوص الفرعية

  // ألوان أخرى
  static const Color errorColor = Color(0xFFDC2626); // أحمر للخطأ
  static const Color successColor = Color(0xFF16A34A); // أخضر للنجاح
  static const Color inputFillColor =
      Color(0xFFF1F5F9); // لون خلفية حقول الإدخال
  static const Color borderColor =
      Color(0xFFE2E8F0); // لون خفيف جداً للحدود إن وجدت

  // توكنات التخطيط (شبكة 8px)
  static const double spaceXs = 8;
  static const double spaceSm = 12;
  static const double spaceMd = 16;
  static const double spaceLg = 20;
  static const double spaceXl = 24;
  static const double screenPadding = 20;
  static const double cardRadius = 20;
  static const double cardRadiusLg = 24;
  static const double ctaHeight = 52;

  /// Clears the floating pill bottom nav (`extendBody: true`, ~76 + SafeArea + pad).
  static const double homeBottomClearance = 120;

  static BoxDecoration surfaceCardDecoration({
    Color? color,
    double radius = cardRadius,
    bool elevated = true,
    Color? borderColor,
  }) {
    return BoxDecoration(
      color: color ?? surfaceColor,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: borderColor ?? AppTheme.borderColor.withOpacity(0.7),
      ),
      boxShadow: elevated
          ? [
              BoxShadow(
                color: primaryColor.withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ]
          : null,
    );
  }

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
            color: primaryColor,
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
          displayColor: primaryColor,
        );
  }

  static ThemeData _buildLightTheme() {
    const scheme = ColorScheme(
      brightness: Brightness.light,
      primary: primaryColor,
      onPrimary: Colors.white,
      secondary: accentColor,
      onSecondary: Colors.white,
      error: errorColor,
      onError: Colors.white,
      surface: surfaceColor,
      onSurface: textPrimary,
    );

    // شكل الكروت الحديث (بدون حدود قوية، مع ظل خفيف)
    final roundedCard = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: 'Tajawal',
      colorScheme: scheme,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,
      canvasColor: backgroundColor,
      dividerColor: borderColor,
      textTheme: _textTheme(),
      appBarTheme: const AppBarTheme(
        backgroundColor: surfaceColor,
        foregroundColor: primaryColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          fontFamily: 'Tajawal',
          color: primaryColor,
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
        iconTheme: IconThemeData(color: primaryColor),
      ),
      cardTheme: CardTheme(
        color: surfaceColor,
        elevation: 2, // إضافة ظل خفيف للكروت
        shadowColor: Colors.black.withOpacity(0.05),
        surfaceTintColor: Colors.transparent,
        shape: roundedCard,
        margin: const EdgeInsets.only(bottom: 16),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(0, 56), // تسمح بالاستخدام داخل Rows أيضًا
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
          minimumSize: const Size(0, 56),
          foregroundColor: primaryColor,
          side: const BorderSide(color: primaryColor, width: 1.5),
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
        fillColor: inputFillColor, // خلفية رمادية فاتحة للحقول
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        hintStyle: TextStyle(color: textSecondary.withOpacity(0.7)),
        labelStyle: const TextStyle(color: textSecondary),
        prefixIconColor: textSecondary,
        suffixIconColor: textSecondary,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none, // بدون إطار في الوضع العادي
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
              color: primaryColor, width: 1.5), // إطار عند التركيز
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: errorColor, width: 1.0),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: errorColor, width: 1.5),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surfaceColor,
        indicatorColor: primaryLight.withOpacity(0.15),
        elevation: 10,
        shadowColor: Colors.black.withOpacity(0.1),
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
        elevation: 15,
        type: BottomNavigationBarType.fixed,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: inputFillColor,
        selectedColor: primaryColor.withOpacity(0.1),
        labelStyle:
            const TextStyle(color: textPrimary, fontWeight: FontWeight.w600),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: primaryColor,
        contentTextStyle:
            const TextStyle(color: Colors.white, fontFamily: 'Tajawal'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      dividerTheme: const DividerThemeData(
        color: borderColor,
        thickness: 1,
        space: 24,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected)
                ? Colors.white
                : Colors.white),
        trackColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected)
                ? primaryColor
                : textSecondary.withOpacity(0.4)),
      ),
    );
  }

  static ThemeData get lightTheme => _buildLightTheme();

  static ThemeData get darkTheme {
    const darkBg = Color(0xFF0F1419);
    const darkSurface = Color(0xFF1A2332);
    const darkText = Color(0xFFE2E8F0);
    const darkInput = Color(0xFF243044);
    const darkBorder = Color(0xFF334155);

    const scheme = ColorScheme.dark(
      primary: primaryLight,
      onPrimary: Colors.white,
      secondary: accentColor,
      onSecondary: Colors.white,
      error: errorColor,
      onError: Colors.white,
      surface: darkSurface,
      onSurface: darkText,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: 'Tajawal',
      colorScheme: scheme,
      primaryColor: primaryLight,
      scaffoldBackgroundColor: darkBg,
      canvasColor: darkBg,
      dividerColor: darkBorder,
      appBarTheme: const AppBarTheme(
        backgroundColor: darkSurface,
        foregroundColor: darkText,
        elevation: 0,
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardTheme(
        color: darkSurface,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryLight,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkInput,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: primaryLight,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}
