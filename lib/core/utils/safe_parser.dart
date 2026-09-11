import 'package:flutter/material.dart';

class SafeParser {
  static String getString(dynamic val, [String fallback = '']) {
    if (val == null) return fallback;
    if (val is String) return val;
    if (val is Map) {
      return val['name']?.toString() ?? 
             val['status']?.toString() ?? 
             val['title']?.toString() ?? 
             val['description']?.toString() ?? 
             fallback;
    }
    return val.toString();
  }

  static double getDouble(dynamic val) {
    if (val == null) return 0.0;
    if (val is num) return val.toDouble();
    return double.tryParse(val.toString()) ?? 0.0;
  }

  static Color getColor(dynamic val, [Color fallback = const Color(0xff2563EB)]) {
    if (val is Color) return val;
    return fallback;
  }

  static IconData getIcon(dynamic val, [IconData fallback = Icons.notifications_none_rounded]) {
    if (val is IconData) return val;
    return fallback;
  }
}
