import 'package:flutter/material.dart';

class AppFonts {
  static const String inter = 'Inter';
  static const String outfit = 'Outfit';
  static const String montserrat = 'Montserrat';
}

class AppColors {
  static const Color orange = Color(0xFFF47B20);
  static const Color orangeLight = Color(0xFFFF9A4D);
  static const Color orangeDark = Color(0xFFD4640A);
  static const Color orangeGlow = Color(0xFFF47B20);
  static const Color beige = Color(0xFFF5E6D3);
  static const Color beigeLight = Color(0xFFFAF4ED);
  static const Color beigeMid = Color(0xFFEDD9C0);

  // Cream palette — primary background/surface family
  static const Color originalCream = Color(0xFFFDF7E4);
  static const Color originalCreamLight = Color(0xFFFAF0D7);
  static const Color originalCreamMid = Color(0xFFF8EAC8);
  static const Color originalCreamAccent = Color(0xFFF5E3B9);

  // Text / UI colours
  static const Color navy = Color(0xFF1F2937); // Deep Tech Navy — text & icons
  static const Color navyMuted = Color(
    0xFF374151,
  ); // Slightly lighter navy for secondary text
  static const Color dark = Color(0xFF111111); // Industrial Black

  static const Color white = Color(0xFFFFFFFF);
  static const Color cream = Color(0xFFFFF8F0);
  static const Color offWhite = Color(0xFFF8F6F3);
  static const Color grey = Color(0xFF9E9E9E);
  static const Color lightGrey = Color(0xFFF2F2F2);
  static const Color success = Color(0xFF34C759);
  static const Color error = Color(0xFFFF3B30);
  static const Color warning = Color(0xFFFFCC00);

  static const LinearGradient creamGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [originalCream, originalCreamLight, originalCreamMid],
  );

  // Keep navyGradient as alias for backwards compat with screens
  static const LinearGradient navyGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [originalCream, originalCreamLight, originalCreamMid],
  );

  static const LinearGradient orangeGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [orangeLight, orange, orangeDark],
  );

  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [originalCream, originalCreamLight],
    stops: [0.0, 1.0],
  );
}

class AppTheme {
  static ThemeData get lightTheme {
    const inter = AppFonts.inter;
    final base = ThemeData(useMaterial3: true);
    return base.copyWith(
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.orange,
        primary: AppColors.orange,
        secondary: AppColors.navy,
        surface: AppColors.originalCream,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: AppColors.originalCream,
      textTheme: base.textTheme
          .apply(fontFamily: inter)
          .copyWith(
            displayLarge: const TextStyle(
              fontFamily: inter,
              fontSize: 34,
              fontWeight: FontWeight.w700,
              color: AppColors.navy,
              letterSpacing: -0.5,
            ),
            displayMedium: const TextStyle(
              fontFamily: inter,
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: AppColors.navy,
              letterSpacing: -0.3,
            ),
            headlineLarge: const TextStyle(
              fontFamily: inter,
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: AppColors.navy,
            ),
            headlineMedium: const TextStyle(
              fontFamily: inter,
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.navy,
            ),
            titleLarge: const TextStyle(
              fontFamily: inter,
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.navy,
            ),
            titleMedium: const TextStyle(
              fontFamily: inter,
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.navy,
            ),
            bodyLarge: const TextStyle(
              fontFamily: inter,
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: AppColors.navy,
            ),
            bodyMedium: const TextStyle(
              fontFamily: inter,
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: AppColors.navyMuted,
            ),
            bodySmall: const TextStyle(
              fontFamily: inter,
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: AppColors.grey,
            ),
            labelLarge: const TextStyle(
              fontFamily: inter,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.white,
              letterSpacing: 0.3,
            ),
          ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.beige, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.beige, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.orange, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),
        hintStyle: const TextStyle(
          fontFamily: inter,
          color: AppColors.grey,
          fontSize: 14,
        ),
        prefixIconColor: AppColors.grey,
        suffixIconColor: AppColors.grey,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.orange,
          foregroundColor: AppColors.white,
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 32),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
          textStyle: const TextStyle(
            fontFamily: inter,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.orange,
          side: const BorderSide(color: AppColors.orange, width: 2),
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 32),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontFamily: inter,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: AppColors.navy),
        titleTextStyle: TextStyle(
          fontFamily: inter,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.navy,
        ),
      ),
    );
  }
}
