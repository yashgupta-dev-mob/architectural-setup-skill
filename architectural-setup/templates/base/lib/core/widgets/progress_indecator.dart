// GENERIC: defaultTargetPlatform instead of dart:io Platform, so it also works on the web.
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class ProgressIndecator extends StatelessWidget {
  final Color? color;
  final double? strokeWidth;

  const ProgressIndecator({super.key, this.color, this.strokeWidth});

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? Theme.of(context).colorScheme.primary;

    return defaultTargetPlatform == TargetPlatform.iOS
        ? Center(
            child: CupertinoActivityIndicator(
              animating: true,
              radius: 15,
              color: effectiveColor,
            ),
          )
        : Center(
            child: CircularProgressIndicator(
              color: effectiveColor,
              strokeWidth: strokeWidth,
            ),
          );
  }
}
