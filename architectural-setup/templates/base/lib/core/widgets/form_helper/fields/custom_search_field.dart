import 'dart:async';

import 'package:flutter/material.dart';

class CustomSearchBar extends StatefulWidget {
  final String label;
  final String? initialValue;
  final void Function(String) onChanged;
  final String? Function(String?)? validator;
  final bool readOnly;
  final bool autofocus;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? hintText;
  final Duration debounceDuration;

  /// Called, undebounced, when the keyboard's search action is pressed.
  final void Function(String)? onSubmitted;

  /// Shown at the trailing edge, after the clear button, e.g. an accent
  /// camera button.
  final Widget? trailing;

  /// Corner radius of the field; 28 gives a pill at the default height.
  final double borderRadius;

  const CustomSearchBar({
    super.key,
    required this.label,
    this.initialValue,
    required this.onChanged,
    this.validator,
    this.readOnly = false,
    this.autofocus = false,
    this.controller,
    this.focusNode,
    this.hintText,
    this.debounceDuration = const Duration(milliseconds: 300),
    this.onSubmitted,
    this.trailing,
    this.borderRadius = 16,
  });

  @override
  State<CustomSearchBar> createState() => _CustomSearchBarState();
}

class _CustomSearchBarState extends State<CustomSearchBar> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();

    _controller = widget.controller ?? TextEditingController();
    _focusNode = widget.focusNode ?? FocusNode();

    if (widget.initialValue != null) {
      _controller.text = widget.initialValue!;
    }

    _focusNode.addListener(_onFocusChange);
    _controller.addListener(_onTextChange);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _focusNode.removeListener(_onFocusChange);
    _controller.removeListener(_onTextChange);

    if (widget.controller == null) {
      _controller.dispose();
    }

    if (widget.focusNode == null) {
      _focusNode.dispose();
    }

    super.dispose();
  }

  void _onFocusChange() {
    setState(() {});
  }

  void _onTextChange() {
    // Rebuild so the clear button appears/disappears immediately,
    // even when the text changes programmatically.
    setState(() {});
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) {
      _debounce!.cancel();
    }

    _debounce = Timer(widget.debounceDuration, () {
      widget.onChanged(query);
    });
  }

  void _clearSearch() {
    _debounce?.cancel();
    _controller.clear();
    widget.onChanged('');
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final hasFocus = _focusNode.hasFocus;
    final hasText = _controller.text.isNotEmpty;

    final clearButton = hasText
        ? IconButton(
            icon: Icon(
              Icons.clear_rounded,
              color: colorScheme.onSurfaceVariant,
              size: 20,
            ),
            onPressed: _clearSearch,
            splashRadius: 20,
          )
        : null;
    final trailing = widget.trailing;
    final Widget? suffix = trailing == null
        ? clearButton
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [?clearButton, trailing],
          );

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(widget.borderRadius),
        border: Border.all(
          color: hasFocus
              ? colorScheme.primary
              : colorScheme.outline.withValues(alpha: 0.3),
          width: hasFocus ? 1.5 : 1,
        ),
        boxShadow: hasFocus
            ? [
                BoxShadow(
                  color: colorScheme.primary.withValues(alpha: 0.18),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.borderRadius - 1),
        child: TextFormField(
          controller: _controller,
          focusNode: _focusNode,
          readOnly: widget.readOnly,
          autofocus: widget.autofocus,
          onChanged: _onSearchChanged,
          onFieldSubmitted: widget.onSubmitted,
          textInputAction: TextInputAction.search,
          validator: widget.validator,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontSize: 15,
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w400,
          ),
          cursorColor: colorScheme.primary,
          decoration: InputDecoration(
            hintText: widget.hintText ?? 'Search ${widget.label}...',
            hintStyle: theme.textTheme.bodyLarge?.copyWith(
              fontSize: 15,
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w400,
            ),
            filled: false,
            prefixIcon: Icon(
              Icons.search_rounded,
              color: hasFocus
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
              size: 22,
            ),
            suffixIcon: suffix,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            errorBorder: InputBorder.none,
            focusedErrorBorder: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            isDense: true,
          ),
        ),
      ),
    );
  }
}
