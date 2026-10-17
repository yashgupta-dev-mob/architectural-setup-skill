import 'package:flutter/material.dart';

import '../buttons/circle_icon_button.dart';
import '../../theme/app_theme.dart';

/// A bottom sheet that asks the user to choose something: an icon, a
/// serif title, a close button, the choices ([child]) and an optional
/// [footer] for buttons such as "Clear" and "Apply".
///
/// Open it with [AppPickerSheet.show], and close it from a choice with
/// `Navigator.of(context).pop(value)`. To tell the user something and
/// wait for an acknowledgement, use `AppInfoSheet` instead.
class AppPickerSheet extends StatelessWidget {
  const AppPickerSheet({
    super.key,
    required this.title,
    this.icon,
    required this.child,
    this.footer,
    this.onClose,
  });

  /// The sheet's close button, for tests.
  static const Key closeKey = Key('appPickerSheet_closeButton');

  final String title;

  /// Shown in a tinted tile before the title; null shows the title alone.
  final IconData? icon;

  /// The choices. It scrolls when it is taller than the screen allows.
  final Widget child;

  /// Pinned under the choices; it does not scroll.
  final Widget? footer;

  /// Replaces closing the sheet with no result.
  final VoidCallback? onClose;

  /// Opens the sheet [builder] returns over the whole screen, bottom bar
  /// included. Completes with the value the sheet was popped with, or null
  /// when the user closed it any other way.
  static Future<T?> show<T>(
    BuildContext context, {
    required WidgetBuilder builder,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      useRootNavigator: true,
      useSafeArea: true,
      // Lets the sheet take the height its choices need.
      isScrollControlled: true,
      showDragHandle: true,
      builder: builder,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Padding(
      // Keeps the sheet above the keyboard.
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 16, 12),
              child: Row(
                children: [
                  if (icon case final icon?) ...[
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: colors.secondary.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(icon, size: 24, color: colors.secondary),
                    ),
                    const SizedBox(width: 14),
                  ],
                  Expanded(
                    child: Semantics(
                      header: true,
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: colors.onSurface,
                          fontFamily: AppTheme.displayFontFamily,
                          fontWeight: FontWeight.w400,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  CircleIconButton(
                    key: closeKey,
                    icon: Icons.close_rounded,
                    tooltip: 'Close',
                    size: 40,
                    onPressed: onClose ?? () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                child: child,
              ),
            ),
            if (footer != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: footer,
              ),
          ],
        ),
      ),
    );
  }
}
