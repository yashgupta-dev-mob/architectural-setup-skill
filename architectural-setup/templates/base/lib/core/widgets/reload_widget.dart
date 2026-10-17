import 'package:flutter/material.dart';

/// Centred error message with a retry button. Colours come from the theme
/// unless [color] is given.
class ReloadWidget extends StatelessWidget {
  final String errorMessage;
  final VoidCallback onReload;
  final Color? color;

  const ReloadWidget({
    super.key,
    required this.errorMessage,
    required this.onReload,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final foreground = color ?? theme.colorScheme.onSurface;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              errorMessage,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: foreground),
            ),
            IconButton(
              key: const Key('reload_button'),
              tooltip: 'Retry',
              icon: Icon(Icons.refresh, color: foreground),
              onPressed: onReload,
            ),
          ],
        ),
      ),
    );
  }
}
