import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Brand Primaries (Dev Motors Automotive Red)
  static const Color primary = Color(0xffD32F2F);
  static const Color primaryDark = Color(0xffB71C1C);
  static const Color primaryLight = Color(0xffFFEBEE);

  // Neutral & Executive Slate Palette
  static const Color slateDark = Color(0xff0F172A);
  static const Color slateMedium = Color(0xff1E293B);
  static const Color slateLight = Color(0xff334155);

  // Backgrounds & Surfaces
  static const Color background = Color(0xffF8FAFC);
  static const Color surface = Colors.white;
  static const Color surfaceMuted = Color(0xffF1F5F9);
  static const Color cardBorder = Color(0xffE2E8F0);
  static const Color border = Color(0xffE2E8F0);

  // Typography
  static const Color textPrimary = Color(0xff0F172A);
  static const Color textSecondary = Color(0xff64748B);
  static const Color textMuted = Color(0xff94A3B8);
  static const Color textWhite = Colors.white;

  // Semantic Feedback Colors & Tinted Backgrounds
  static const Color success = Color(0xff10B981);
  static const Color successLight = Color(0xffECFDF5);
  static const Color successBorder = Color(0xffA7F3D0);

  static const Color warning = Color(0xffF59E0B);
  static const Color warningLight = Color(0xffFFFBEB);
  static const Color warningBorder = Color(0xffFDE68A);

  static const Color danger = Color(0xffEF4444);
  static const Color dangerLight = Color(0xffFEF2F2);
  static const Color dangerBorder = Color(0xffFECACA);

  static const Color info = Color(0xff3B82F6);
  static const Color infoLight = Color(0xffEFF6FF);
  static const Color infoBorder = Color(0xffBFDBFE);

  static const Color purple = Color(0xff8B5CF6);
  static const Color purpleLight = Color(0xffF5F3FF);

  // Status Badge Helper
  static Color getStatusColor(String? status) {
    final s = (status ?? '').toUpperCase();
    if (s.contains('PAID') || s.contains('APPROVED_2') || s == 'SETTLED') {
      return success;
    } else if (s.contains('REJECT')) {
      return danger;
    } else if (s.contains('OWNER') || s == 'APPROVED_1' || s == 'APPROVED') {
      return purple;
    } else if (s.contains('CASHIER')) {
      return info;
    } else {
      return warning;
    }
  }

  static Color getStatusLightBg(String? status) {
    final s = (status ?? '').toUpperCase();
    if (s.contains('PAID') || s.contains('APPROVED_2') || s == 'SETTLED') {
      return successLight;
    } else if (s.contains('REJECT')) {
      return dangerLight;
    } else if (s.contains('OWNER') || s == 'APPROVED_1' || s == 'APPROVED') {
      return purpleLight;
    } else if (s.contains('CASHIER')) {
      return infoLight;
    } else {
      return warningLight;
    }
  }
}