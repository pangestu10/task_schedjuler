// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Psychological Color Palette -> "Mindful Focus"
  // Blue/Purple: Calm, Trust, Wisdom
  // Teal/Green: Growth, Balance
  // Soft White: Clarity, Space
  static const Color primaryColor = Color(0xFF6C63FF); // Modern Indigo
  static const Color secondaryColor = Color(0xFF3F3D56); // Deep Charcoal
  static const Color accentColor = Color(0xFF00BFA6); // Calm Teal
  static const Color backgroundColor = Color(0xFFF4F6F8); // Soft Cloud
  static const Color surfaceColor = Colors.white;
  static const Color errorColor = Color(0xFFFF6B6B); // Soft Red

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,
      
      // Color Scheme
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        secondary: accentColor,
        surface: surfaceColor,
        background: backgroundColor,
        error: errorColor,
        brightness: Brightness.light,
      ),

      // Typography
      textTheme: TextTheme(
        displayLarge: GoogleFonts.poppins(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: secondaryColor,
        ),
        displayMedium: GoogleFonts.poppins(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: secondaryColor,
        ),
        displaySmall: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: secondaryColor,
        ),
        headlineMedium: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: secondaryColor,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 16,
          color: secondaryColor.withOpacity(0.8),
          height: 1.5,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          color: secondaryColor.withOpacity(0.8),
          height: 1.5,
        ),
        labelLarge: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),

      // AppBar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: backgroundColor,
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: 0,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: secondaryColor,
        ),
        iconTheme: const IconThemeData(color: secondaryColor),
      ),

      // Card Theme - Soft & Floated
      cardTheme: CardThemeData(
        color: surfaceColor,
        elevation: 2,
        shadowColor: primaryColor.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      ),

      // Input Decoration - Clean & Rounded
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primaryColor, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: errorColor, width: 1.5),
        ),
        labelStyle: GoogleFonts.inter(color: secondaryColor.withOpacity(0.6)),
        hintStyle: GoogleFonts.inter(color: secondaryColor.withOpacity(0.4)),
      ),

      // Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 4,
          shadowColor: primaryColor.withOpacity(0.4),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          textStyle: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      // Icon Theme
      iconTheme: const IconThemeData(
        color: secondaryColor,
        size: 24,
      ),
      
      // Floating Action Button
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: accentColor,
        foregroundColor: Colors.white,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),

      // Navigation Bar Theme (Modern Bottom Nav)
      navigationBarTheme: NavigationBarThemeData(
        height: 70,
        backgroundColor: surfaceColor,
        elevation: 0,
        indicatorColor: primaryColor.withOpacity(0.15),
        labelTextStyle: MaterialStateProperty.all(
          GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: secondaryColor,
          ),
        ),
        iconTheme: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return const IconThemeData(color: primaryColor, size: 26);
          }
          return IconThemeData(color: secondaryColor.withOpacity(0.6), size: 24);
        }),
      ),
    );
  }
}
