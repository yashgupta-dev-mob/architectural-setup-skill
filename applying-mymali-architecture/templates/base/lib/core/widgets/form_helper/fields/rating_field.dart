import 'package:flutter/material.dart';

import '../../../theme/app_tones.dart';

/// A row of stars to give a rating: tapping the n-th star picks n. The
/// first [value] stars are filled in the theme's rating tone.
///
/// [errorText] shows an error without a Form validation; [validator] runs
/// in a Form with the picked rating as text ("0" when none is picked).
class RatingField extends StatelessWidget {
  const RatingField({
    super.key,
    required this.value,
    required this.onChanged,
    this.maxRating = 5,
    this.starSize = 32,
    this.keyPrefix,
    this.enabled = true,
    this.errorText,
    this.validator,
  });

  /// The picked rating; 0 when none is picked.
  final int value;
  final ValueChanged<int> onChanged;
  final int maxRating;
  final double starSize;

  /// Each star gets the key `<keyPrefix>_<n>`, n from 1.
  final String? keyPrefix;
  final bool enabled;
  final String? errorText;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final filled = AppTones.of(context).rating;

    return FormField<int>(
      initialValue: value,
      validator: validator == null
          ? null
          : (picked) => validator!('${picked ?? 0}'),
      builder: (field) {
        final error = field.errorText ?? errorText;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var star = 1; star <= maxRating; star++)
                  Semantics(
                    button: true,
                    selected: star <= value,
                    label: '$star star${star == 1 ? '' : 's'}',
                    child: InkResponse(
                      key: keyPrefix == null ? null : Key('${keyPrefix}_$star'),
                      radius: starSize * 0.7,
                      onTap: enabled
                          ? () {
                              field.didChange(star);
                              onChanged(star);
                            }
                          : null,
                      child: Padding(
                        padding: const EdgeInsets.all(3),
                        child: Icon(
                          star <= value
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                          size: starSize,
                          color: star <= value
                              ? filled
                              : colors.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            if (error != null && error.isNotEmpty) ...[
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  error,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.error,
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
