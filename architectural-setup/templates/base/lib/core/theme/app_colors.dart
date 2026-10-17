// GENERIC: per app. The ONLY file with colour values: the app's own brand colours, never the source app's.
import 'package:flutter/material.dart';

abstract final class AppColors {
  /// The app's brand colour (its old `primarySwatch`, `colorSchemeSeed` or
  /// most used button colour).
  static const Color primary = Colors.teal;

  // Tones that say why something happened (see `AppTones`). Each has a
  // light and a dark value. Use the colours the app already shows for a
  // success, a calm note and a warning.
  static const Color success = Color(0xFF2E7D32);
  static const Color successOnDark = Color(0xFF81C784);
  static const Color sky = Color(0xFF64B5F6);
  static const Color apricot = Color(0xFFEF6C00);
  static const Color apricotOnDark = Color(0xFFFFB74D);

  /// Rating stars.
  static const Color star = Color(0xFFF5C518);
}
