import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Typography for Nusuk for Iman
/// Uses Amiri for Arabic content, clean sans-serif for UI
class AppTextStyles {
  AppTextStyles._();

  // Arabic Qur'an text
  static TextStyle quranText({double fontSize = 28}) => GoogleFonts.amiri(
    fontSize: fontSize,
    height: 2.0,
    color: const Color(0xFF2D2D2D),
  );

  // Calligraphic Arabic text for titles and dedication
  static TextStyle calligraphy({double fontSize = 24, Color? color}) => GoogleFonts.arefRuqaa(
    fontSize: fontSize,
    color: color ?? const Color(0xFF2D2D2D),
    height: 1.5,
  );

  // Arabic body text (hadith, dhikr, duaa)
  static TextStyle arabicBody({double fontSize = 20}) => GoogleFonts.amiri(
    fontSize: fontSize,
    height: 1.8,
    color: const Color(0xFF2D2D2D),
  );

  // UI heading
  static TextStyle heading({double fontSize = 22}) => const TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: Color(0xFF2D2D2D),
    letterSpacing: -0.3,
  );

  // UI body
  static TextStyle body({double fontSize = 16}) => const TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: Color(0xFF2D2D2D),
    height: 1.5,
  );

  // Subtle dedication text
  static TextStyle dedication() => const TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: Color(0xFF9E9E9E),
    height: 1.4,
  );

  // Counter display
  static TextStyle counter() => const TextStyle(
    fontSize: 56,
    fontWeight: FontWeight.w300,
    color: Color(0xFF0E5A4F),
  );
}
