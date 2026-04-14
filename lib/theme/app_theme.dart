import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Vintage Ledger Palette
  static const Color paperBackground = Color(0xFFFDFBF7); // Soft bone/cream
  static const Color inkyNavy = Color(0xFF1B263B);       // Deep inky navy for primary
  static const Color classicCrimson = Color(0xFF8B1E1E); // Deep bordeaux for accents
  static const Color pencilGrey = Color(0xFF5D6D7E);    // Muted grey for subtle text
  static const Color inkBlack = Color(0xFF1C1C1C);      // Almost black for main text
  static const Color borderInk = Color(0xFF2C3E50);     // Structured borders

  static ThemeData get theme {
    final textTheme = GoogleFonts.ebGaramondTextTheme().copyWith(
      headlineLarge: GoogleFonts.ebGaramond(
        color: inkBlack,
        fontSize: 36,
        fontWeight: FontWeight.bold,
        letterSpacing: -0.5,
      ),
      headlineMedium: GoogleFonts.ebGaramond(
        color: inkBlack,
        fontSize: 28,
        fontWeight: FontWeight.w600,
      ),
      headlineSmall: GoogleFonts.ebGaramond(
        color: inkBlack,
        fontSize: 24,
        fontWeight: FontWeight.w600,
      ),
      titleLarge: GoogleFonts.ebGaramond(
        color: inkBlack,
        fontSize: 20,
        fontWeight: FontWeight.w500,
      ),
      bodyLarge: GoogleFonts.publicSans(
        color: inkBlack,
        fontSize: 16,
        height: 1.5,
      ),
      bodyMedium: GoogleFonts.publicSans(
        color: inkBlack,
        fontSize: 14,
        height: 1.4,
      ),
      labelLarge: GoogleFonts.publicSans(
        color: Colors.white,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.2,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: paperBackground,
      colorScheme: ColorScheme.fromSeed(
        seedColor: inkyNavy,
        primary: inkyNavy,
        secondary: classicCrimson,
        surface: Colors.white,
        background: paperBackground,
      ),
      textTheme: textTheme,
      
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.ebGaramond(
          color: inkBlack,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: const IconThemeData(color: inkBlack),
      ),

      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: borderInk, width: 0.8),
          borderRadius: BorderRadius.circular(4.0),
        ),
        margin: EdgeInsets.zero,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: inkyNavy,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4.0),
          ),
          textStyle: GoogleFonts.publicSans(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: inkyNavy,
          side: const BorderSide(color: inkyNavy, width: 1.5),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4.0),
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4.0),
          borderSide: const BorderSide(color: borderInk, width: 1.0),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4.0),
          borderSide: const BorderSide(color: borderInk, width: 1.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4.0),
          borderSide: const BorderSide(color: inkyNavy, width: 2.0),
        ),
        labelStyle: GoogleFonts.publicSans(color: pencilGrey),
        floatingLabelStyle: GoogleFonts.publicSans(color: inkyNavy, fontWeight: FontWeight.bold),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      ),

      dividerTheme: const DividerThemeData(
        color: borderInk,
        thickness: 0.8,
        space: 24,
      ),
    );
  }
}