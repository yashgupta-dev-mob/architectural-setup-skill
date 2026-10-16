// GENERIC: per app. MyMali's AppTheme names (light, dark, _build, fontSizeFactor, displayFontFamily) over the app's own ThemeData.
import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_tones.dart';

abstract final class AppTheme {
  /// The app's own light theme, exactly as it was built before (same
  /// constructor, same arguments, values moved into [AppColors]).
  static ThemeData get light => _build(
    AppTones.light,
    ThemeData(colorSchemeSeed: AppColors.primary, useMaterial3: true),
  );

  /// The app's own dark theme, exactly as before.
  static ThemeData get dark => _build(
    AppTones.dark,
    ThemeData(
      colorSchemeSeed: AppColors.primary,
      brightness: Brightness.dark,
      useMaterial3: true,
    ),
  );

  /// Scales the text theme. 1.0 keeps the app's sizes; change it only if
  /// the app already scaled its type.
  static const double fontSizeFactor = 1.0;

  /// The serif or display font used for section titles, as registered in
  /// `pubspec.yaml`, or null to keep the platform font.
  static const String? displayFontFamily = null;

  static ThemeData _build(AppTones tones, ThemeData base) {
    return base.copyWith(extensions: [tones]);
  }
}
