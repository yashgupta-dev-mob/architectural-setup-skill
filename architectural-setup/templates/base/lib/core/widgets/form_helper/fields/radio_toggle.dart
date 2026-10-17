// ignore_for_file: avoid_unnecessary_containers
import 'package:flutter/material.dart';

class RadioToggle extends StatelessWidget {
  final Function(bool)? onChanged;
  final bool initialValue;
  final Color? radioColor;
  const RadioToggle({
    super.key,
    required this.initialValue,
    required this.onChanged,
    this.radioColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Switch.adaptive(
        activeThumbColor: radioColor ?? Theme.of(context).colorScheme.primary,
        value: initialValue,
        onChanged: onChanged,
      ),
    );
  }
}
