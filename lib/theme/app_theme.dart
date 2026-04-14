import 'package:flutter/material.dart';

class AppTheme {
  // Converted from HSL colors in the CSS
  static const Color primaryBlue = Color(0xFF2366F2);
  static const Color primaryPurple = Color(0xFF975DF5);
  static const Color cardBackground = Color(0xF2FFFFFF); // white with 95% opacity
  static const Color textColor = Color(0xFF16191E);
  static const Color subtleTextColor = Color(0xFF6B7280);
  static const Color destructiveRed = Color(0xFFE53E3E);

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryBlue, primaryPurple],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static ThemeData get theme {
    return ThemeData(
      scaffoldBackgroundColor: primaryBlue,
      fontFamily: 'Inter', // Make sure to add a font if you want a specific one
      // FIX: Changed CardTheme to CardThemeData
      cardTheme: CardThemeData(
        color: cardBackground,
        elevation: 4.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        shadowColor: Colors.black.withOpacity(0.1),
        margin: EdgeInsets.zero,
      ),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(
            color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
        headlineSmall: TextStyle(
            color: textColor, fontSize: 24, fontWeight: FontWeight.bold),
        titleMedium:
            TextStyle(color: Colors.white, fontSize: 16, letterSpacing: 0.5),
        bodyMedium: TextStyle(color: textColor, fontSize: 16, height: 1.5),
        labelLarge:
            TextStyle(color: Colors.white, fontSize: 16, letterSpacing: 0.5),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          padding: MaterialStateProperty.all(
            const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          ),
          shape: MaterialStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
          ),
          foregroundColor: MaterialStateProperty.all(Colors.white),
          textStyle: MaterialStateProperty.all(
            const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          elevation: MaterialStateProperty.resolveWith<double>(
            (Set<MaterialState> states) {
              if (states.contains(MaterialState.pressed)) return 8.0;
              return 4.0;
            },
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: const BorderSide(color: primaryBlue, width: 2.0),
        ),
        labelStyle: const TextStyle(color: subtleTextColor),
        floatingLabelStyle: const TextStyle(color: primaryBlue),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      ),
    );
  }
}