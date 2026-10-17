// GENERIC: doc comments made neutral (no Mali Coins).
import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Colours that say *why* something happened, beyond what the
/// [ColorScheme] offers: a success, a calm note and a warm gift. The
/// alert red stays `colorScheme.error`.
///
/// Read them with `AppTones.of(context)`. The values live in [AppColors]
/// and are registered on both themes by `AppTheme`, so widgets need no
/// brightness checks of their own.
@immutable
class AppTones extends ThemeExtension<AppTones> {
  const AppTones({
    required this.success,
    required this.info,
    required this.warning,
    this.rating = AppColors.star,
  });

  static const AppTones light = AppTones(
    success: AppColors.success,
    info: AppColors.sky,
    warning: AppColors.apricot,
    rating: AppColors.star,
  );

  static const AppTones dark = AppTones(
    success: AppColors.successOnDark,
    info: AppColors.sky,
    warning: AppColors.apricotOnDark,
    rating: AppColors.star,
  );

  /// Something good: a reward earned, an order delivered.
  final Color success;

  /// A calm note: credit spent on purpose.
  final Color info;

  /// Warm attention: a gift, a bonus.
  final Color warning;

  /// A filled rating star and the bars of a rating summary.
  final Color rating;

  /// The tones of the current theme.
  static AppTones of(BuildContext context) =>
      Theme.of(context).extension<AppTones>() ?? light;

  @override
  AppTones copyWith({
    Color? success,
    Color? info,
    Color? warning,
    Color? rating,
  }) => AppTones(
    success: success ?? this.success,
    info: info ?? this.info,
    warning: warning ?? this.warning,
    rating: rating ?? this.rating,
  );

  @override
  AppTones lerp(ThemeExtension<AppTones>? other, double t) {
    if (other is! AppTones) return this;
    return AppTones(
      success: Color.lerp(success, other.success, t) ?? success,
      info: Color.lerp(info, other.info, t) ?? info,
      warning: Color.lerp(warning, other.warning, t) ?? warning,
      rating: Color.lerp(rating, other.rating, t) ?? rating,
    );
  }
}
