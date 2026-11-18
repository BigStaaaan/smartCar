import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Kinetic Campus Typography System (from DESIGN.md)
/// - Headlines / Display: Bricolage Grotesque
/// - Body, Labels & Captions: Be Vietnam Pro
abstract final class AppTypography {
  static const String fontHeadline = 'Bricolage Grotesque';
  static const String fontBody = 'Be Vietnam Pro';

  // ── Display ──
  static TextStyle displayLg = GoogleFonts.bricolageGrotesque(
    fontSize: 32,
    fontWeight: FontWeight.w800,
    height: 38 / 32,
    letterSpacing: -0.03 * 32,
    color: AppColors.onSurface,
  );

  // ── Headlines ──
  static TextStyle headlineLg = GoogleFonts.bricolageGrotesque(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 34 / 28,
    letterSpacing: -0.02 * 28,
    color: AppColors.onSurface,
  );

  static TextStyle headlineMd = GoogleFonts.bricolageGrotesque(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    height: 28 / 22,
    letterSpacing: -0.015 * 22,
    color: AppColors.onSurface,
  );

  static TextStyle headlineSm = GoogleFonts.bricolageGrotesque(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 24 / 18,
    color: AppColors.onSurface,
  );

  // ── Body ──
  static TextStyle bodyLg = GoogleFonts.beVietnamPro(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 24 / 16,
    color: AppColors.onSurface,
  );

  static TextStyle bodyMd = GoogleFonts.beVietnamPro(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 21 / 14,
    color: AppColors.onSurfaceVariant,
  );

  static TextStyle bodySm = GoogleFonts.beVietnamPro(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 18 / 13,
    color: AppColors.onSurfaceVariant,
  );

  // ── Labels ──
  static TextStyle labelMd = GoogleFonts.beVietnamPro(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 18 / 14,
    letterSpacing: 0.01 * 14,
    color: AppColors.onSurface,
  );

  static TextStyle labelSm = GoogleFonts.beVietnamPro(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    height: 16 / 12,
    letterSpacing: 0.02 * 12,
    color: AppColors.onSurface,
  );

  // ── Caption ──
  static TextStyle caption = GoogleFonts.beVietnamPro(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 16 / 12,
    color: AppColors.onSurfaceVariant,
  );
}
