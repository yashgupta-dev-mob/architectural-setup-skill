import 'package:flutter/material.dart';

import '../buttons/circle_icon_button.dart';
import '../buttons/primary_button.dart';

/// What an [AppInfoSheet] tells the user. It picks the icon and its colour.
enum AppInfoSheetTone {
  /// Something the user should know.
  info,

  /// Something the user did has worked.
  success,

  /// Something went wrong.
  error,
}

/// A bottom sheet that tells the user one thing and waits for them to
/// acknowledge it: an icon, a title, a close button, a message and one
/// button.
///
/// Open it with [AppInfoSheet.show]; do not build it by hand.
class AppInfoSheet extends StatelessWidget {
  const AppInfoSheet({
    super.key,
    required this.title,
    required this.message,
    required this.onAction,
    required this.onClose,
    this.tone = AppInfoSheetTone.info,
    this.icon,
    this.actionLabel = defaultActionLabel,
  });

  static const String defaultActionLabel = 'Got it';

  /// The sheet's button and its close button, for tests.
  static const Key actionKey = Key('appInfoSheet_actionButton');
  static const Key closeKey = Key('appInfoSheet_closeButton');

  final String title;
  final String message;
  final AppInfoSheetTone tone;

  /// Replaces the tone's own icon.
  final IconData? icon;
  final String actionLabel;

  /// Null disables the button.
  final VoidCallback? onAction;
  final VoidCallback? onClose;

  /// Opens the sheet over the whole screen, bottom bar included.
  ///
  /// Completes with `true` when the user pressed the button, and `false`
  /// when they closed the sheet any other way (the close button, a swipe,
  /// a tap outside, system back). So an error with a retry is:
  ///
  /// ```dart
  /// final retry = await AppInfoSheet.show(
  ///   context,
  ///   tone: AppInfoSheetTone.error,
  ///   title: 'Could not save',
  ///   message: 'Check your connection and try again.',
  ///   actionLabel: 'Try again',
  /// );
  /// ```
  static Future<bool> show(
    BuildContext context, {
    required String title,
    required String message,
    AppInfoSheetTone tone = AppInfoSheetTone.info,
    IconData? icon,
    String actionLabel = defaultActionLabel,
    Key? key,
  }) async {
    final acted = await showModalBottomSheet<bool>(
      context: context,
      useRootNavigator: true,
      useSafeArea: true,
      // Lets a long message take the height it needs.
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => AppInfoSheet(
        key: key,
        title: title,
        message: message,
        tone: tone,
        icon: icon,
        actionLabel: actionLabel,
        onAction: () => Navigator.of(sheetContext).pop(true),
        onClose: () => Navigator.of(sheetContext).pop(false),
      ),
    );
    return acted ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final (IconData toneIcon, Color toneColor) = switch (tone) {
      AppInfoSheetTone.info => (Icons.info_outline_rounded, colors.secondary),
      AppInfoSheetTone.success => (Icons.task_alt_rounded, colors.secondary),
      AppInfoSheetTone.error => (Icons.error_outline_rounded, colors.error),
    };

    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 16, 16),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: toneColor.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon ?? toneIcon, size: 24, color: toneColor),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: colors.onSurface,
                        fontWeight: FontWeight.w800,
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
                  onPressed: onClose,
                ),
              ],
            ),
          ),
          Divider(height: 1, thickness: 1, color: colors.outlineVariant),
          // Scrolls when the message is taller than the screen allows.
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              child: Text(
                message,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colors.onSurfaceVariant,
                  height: 1.45,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: PrimaryButton(
              key: actionKey,
              label: actionLabel,
              onPressed: onAction,
            ),
          ),
        ],
      ),
    );
  }
}
