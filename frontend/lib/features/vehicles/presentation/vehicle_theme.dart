import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const vehicleCream = Color(0xffeee7d7);
const vehicleInk = Color(0xff232715);
const vehicleOlive = Color(0xff4f5330);
const vehicleTeal = Color(0xff8ccfc9);
const vehicleBlue = Color(0xffb7c8e0);

ThemeData vehicleTheme() {
  final base = ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: vehicleOlive,
      primary: vehicleOlive,
      onPrimary: vehicleCream,
      surface: vehicleCream,
      onSurface: vehicleInk,
    ),
    scaffoldBackgroundColor: vehicleCream,
  );
  return base.copyWith(
    textTheme: base.textTheme.copyWith(
      displaySmall: GoogleFonts.instrumentSerif(
        textStyle: base.textTheme.displaySmall,
        color: vehicleInk,
      ),
      titleLarge: GoogleFonts.bricolageGrotesque(
        textStyle: base.textTheme.titleLarge,
        fontWeight: FontWeight.w800,
      ),
      bodyMedium: GoogleFonts.bricolageGrotesque(
        textStyle: base.textTheme.bodyMedium,
      ),
      labelLarge: GoogleFonts.bricolageGrotesque(
        textStyle: base.textTheme.labelLarge,
        fontWeight: FontWeight.w600,
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: vehicleCream,
      surfaceTintColor: Colors.transparent,
      foregroundColor: vehicleInk,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xfff3eee3),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: vehicleBlue),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: vehicleBlue),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: vehicleOlive, width: 1.5),
      ),
    ),
  );
}
