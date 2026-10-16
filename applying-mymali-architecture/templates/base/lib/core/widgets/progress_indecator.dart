import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class ProgressIndecator extends StatelessWidget {
  final Color? color;
  final double? strokeWidth;

  const ProgressIndecator({super.key, this.color, this.strokeWidth});

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? Theme.of(context).colorScheme.primary;

    return Platform.isIOS
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
