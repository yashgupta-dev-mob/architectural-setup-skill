import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

/// Pill-shaped call-to-action that is confirmed by dragging its arrow
/// thumb to the right end, for actions that should not fire on a stray
/// tap (e.g. "Review & Pay").
///
/// [onPressed] is called once the thumb is released at the end; released
/// short of it, the thumb springs back and nothing happens. A plain tap
/// only nudges the thumb, to show which way it goes. Screen readers
/// activate the button without the drag.
///
/// A null [onPressed] disables the button, and [isLoading] shows progress
/// and blocks the drag. It fills the width it is given; set its size
/// with [height] and the width of its parent.
class SlideActionButton extends StatefulWidget {
  const SlideActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.prefixLabel,
    this.icon = Icons.arrow_forward_rounded,
    this.isLoading = false,
    this.height = 56,
  });

  /// What the slide does, e.g. "Review & Pay".
  final String label;

  /// Called when the thumb is released at the end of the track.
  final VoidCallback? onPressed;

  /// Shown in bold before [label], separated by a dot; e.g. an amount.
  final String? prefixLabel;

  /// Icon on the thumb.
  final IconData icon;
  final bool isLoading;

  /// Height of the button. The thumb and the chevrons scale with it.
  final double height;

  /// Share of the track the thumb must cover for a release to count.
  static const double completeAt = 0.8;

  @override
  State<SlideActionButton> createState() => _SlideActionButtonState();
}

class _SlideActionButtonState extends State<SlideActionButton>
    with TickerProviderStateMixin {
  /// Gap between the thumb and the edge of the track.
  static const double _inset = 5;

  /// A release slower than this (in logical pixels per second) only
  /// counts past [SlideActionButton.completeAt].
  static const double _flingVelocity = 700;

  /// How far a tap nudges the thumb.
  static const double _nudgeTo = 0.16;

  /// Times the chevrons sweep each time the hint plays.
  static const int _hintSweeps = 3;
  static const Duration _sweepDuration = Duration(milliseconds: 1100);

  /// How far the thumb has travelled: 0 at rest, 1 at the far end.
  late final AnimationController _slide = AnimationController(vsync: this);

  /// Sweeps the chevrons towards the far end, to invite the drag.
  late final AnimationController _hint = AnimationController(
    vsync: this,
    duration: _sweepDuration * _hintSweeps,
  );

  bool _dragging = false;

  /// The thumb reached the end and is on its way back.
  bool _completing = false;
  bool _hintPlayed = false;

  bool get _enabled => widget.onPressed != null && !widget.isLoading;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hintPlayed) {
      _hintPlayed = true;
      _playHint();
    }
  }

  @override
  void didUpdateWidget(SlideActionButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    final wasEnabled = oldWidget.onPressed != null && !oldWidget.isLoading;
    if (!_enabled) {
      _hint
        ..stop()
        ..value = 0;
    } else if (!wasEnabled ||
        oldWidget.label != widget.label ||
        oldWidget.prefixLabel != widget.prefixLabel) {
      _playHint();
    }
  }

  @override
  void dispose() {
    _slide.dispose();
    _hint.dispose();
    super.dispose();
  }

  /// Sweeps the chevrons a few times. It stops by itself, so the button
  /// is still once it has been noticed.
  void _playHint() {
    if (!_enabled || _dragging || _completing) return;
    if (MediaQuery.disableAnimationsOf(context)) return;
    _hint.forward(from: 0);
  }

  void _onDragStart(DragStartDetails details) {
    if (_completing) return;
    _slide.stop();
    _hint
      ..stop()
      ..value = 0;
    setState(() => _dragging = true);
  }

  void _onDragUpdate(DragUpdateDetails details, double travel) {
    if (!_dragging || travel <= 0) return;
    _slide.value += (details.primaryDelta ?? 0) / travel;
  }

  void _onDragEnd(DragEndDetails details) {
    if (!_dragging) return;
    setState(() => _dragging = false);

    final flung =
        (details.primaryVelocity ?? 0) > _flingVelocity && _slide.value > 0.5;
    if (_slide.value >= SlideActionButton.completeAt || flung) {
      _complete();
    } else {
      _springBack();
    }
  }

  void _onDragCancel() {
    if (!_dragging) return;
    setState(() => _dragging = false);
    _springBack();
  }

  /// Runs the thumb to the end, calls [SlideActionButton.onPressed], then
  /// brings the thumb back for the next use.
  Future<void> _complete() async {
    if (_completing || !_enabled) return;
    setState(() => _completing = true);
    _hint
      ..stop()
      ..value = 0;

    await _slide.animateTo(
      1,
      duration: const Duration(milliseconds: 140),
      curve: Curves.easeOut,
    );
    if (!mounted) return;
    HapticFeedback.mediumImpact();
    widget.onPressed?.call();

    // Rests at the end for a moment before it returns.
    await _slide.animateBack(
      0,
      duration: const Duration(milliseconds: 650),
      curve: const Interval(0.4, 1, curve: Curves.easeOutCubic),
    );
    if (!mounted) return;
    setState(() => _completing = false);
    _playHint();
  }

  Future<void> _springBack() async {
    await _slide.animateBack(
      0,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
    if (mounted) _playHint();
  }

  /// A tap is not enough: the thumb hops forward and back to show the way.
  Future<void> _nudge() async {
    if (_completing || _dragging || _slide.isAnimating) return;
    _hint
      ..stop()
      ..value = 0;
    await _slide.animateTo(
      _nudgeTo,
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOut,
    );
    if (!mounted || _dragging) return;
    await _springBack();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final enabled = _enabled;
    final height = widget.height;
    final thumbSize = math.max(0.0, height - 2 * _inset);
    final chevronsSize = Size(thumbSize * 0.5, thumbSize * 0.3);
    final prefix = widget.prefixLabel;
    final hasPrefix = prefix != null && prefix.isNotEmpty;

    final track = enabled
        ? colors.primary
        : colors.primary.withValues(alpha: 0.55);
    final foreground = enabled
        ? colors.onPrimary
        : colors.onPrimary.withValues(alpha: 0.7);
    final labelStyle = theme.textTheme.titleMedium?.copyWith(
      color: foreground,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.2,
    );
    final prefixStyle = const TextStyle(fontWeight: FontWeight.w800);
    final oneLineLabel = TextSpan(
      style: labelStyle,
      children: [
        if (hasPrefix) ...[
          TextSpan(text: prefix, style: prefixStyle),
          TextSpan(
            text: '  ·  ',
            style: TextStyle(color: foreground.withValues(alpha: 0.6)),
          ),
        ],
        TextSpan(text: widget.label),
      ],
    );
    final oneLineWidth = _textWidth(context, oneLineLabel);
    final chevronsEnd = _inset + thumbSize + 6 + chevronsSize.width + 8;
    final endPadding = height * 0.3;

    return Semantics(
      button: true,
      enabled: enabled,
      label: hasPrefix ? '$prefix, ${widget.label}' : widget.label,
      onTap: enabled ? _complete : null,
      excludeSemantics: true,
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final travel = math.max(0.0, width - thumbSize - 2 * _inset);

            // Where the label goes, from roomiest to tightest:
            // - centred on the button, clear of the thumb and chevrons;
            // - between the chevrons and the far end;
            // - narrow (e.g. beside another control): no chevrons, and the
            //   prefix above the label.
            final _LabelLayout layout;
            if (width - 2 * chevronsEnd >= oneLineWidth) {
              layout = _LabelLayout.centred;
            } else if (width - chevronsEnd - endPadding >= oneLineWidth) {
              layout = _LabelLayout.besideChevrons;
            } else {
              layout = _LabelLayout.compact;
            }
            final showChevrons = layout != _LabelLayout.compact;
            final labelLeft = showChevrons
                ? chevronsEnd
                : _inset + thumbSize + 8;
            final labelRight = layout == _LabelLayout.centred
                ? chevronsEnd
                : endPadding;

            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: enabled ? _nudge : null,
              onHorizontalDragStart: enabled ? _onDragStart : null,
              onHorizontalDragUpdate: enabled
                  ? (details) => _onDragUpdate(details, travel)
                  : null,
              onHorizontalDragEnd: enabled ? _onDragEnd : null,
              onHorizontalDragCancel: enabled ? _onDragCancel : null,
              child: DecoratedBox(
                decoration: ShapeDecoration(
                  shape: const StadiumBorder(),
                  gradient: LinearGradient(
                    colors: [
                      Color.alphaBlend(
                        colors.shadow.withValues(alpha: 0.28),
                        track,
                      ),
                      track,
                    ],
                  ),
                  shadows: [
                    if (enabled)
                      BoxShadow(
                        color: colors.shadow.withValues(alpha: 0.18),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                  ],
                ),
                child: widget.isLoading
                    ? Center(
                        child: LoadingAnimationWidget.staggeredDotsWave(
                          color: colors.onPrimary,
                          size: height * 0.5,
                        ),
                      )
                    : AnimatedBuilder(
                        animation: Listenable.merge([_slide, _hint]),
                        builder: (context, _) {
                          final progress = _slide.value;
                          // Fades out over the first part of the slide.
                          final fade = (1 - progress * 4).clamp(0.0, 1.0);

                          return Stack(
                            children: [
                              if (progress > 0)
                                // The part of the track already covered.
                                Positioned(
                                  left: 0,
                                  top: 0,
                                  bottom: 0,
                                  width:
                                      2 * _inset +
                                      thumbSize +
                                      travel * progress,
                                  child: DecoratedBox(
                                    decoration: ShapeDecoration(
                                      shape: const StadiumBorder(),
                                      color: colors.secondaryContainer
                                          .withValues(alpha: 0.2),
                                    ),
                                  ),
                                ),
                              Positioned.fill(
                                child: Padding(
                                  padding: EdgeInsets.only(
                                    left: labelLeft,
                                    right: labelRight,
                                  ),
                                  child: Opacity(
                                    opacity: fade,
                                    child: Center(
                                      // A long label shrinks rather than
                                      // losing its end.
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child:
                                            layout == _LabelLayout.compact &&
                                                hasPrefix
                                            ? Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text(
                                                    prefix,
                                                    maxLines: 1,
                                                    style: labelStyle?.merge(
                                                      prefixStyle,
                                                    ),
                                                  ),
                                                  Text(
                                                    widget.label,
                                                    maxLines: 1,
                                                    style: theme
                                                        .textTheme
                                                        .labelLarge
                                                        ?.copyWith(
                                                          color: foreground,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                  ),
                                                ],
                                              )
                                            : Text.rich(
                                                oneLineLabel,
                                                maxLines: 1,
                                              ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              if (showChevrons)
                                Positioned(
                                  left: _inset + thumbSize + 6,
                                  top: (height - chevronsSize.height) / 2,
                                  child: Opacity(
                                    opacity: fade,
                                    child: CustomPaint(
                                      size: chevronsSize,
                                      painter: _ChevronsPainter(
                                        color: enabled
                                            ? colors.secondaryContainer
                                            : foreground,
                                        phase: (_hint.value * _hintSweeps) % 1,
                                      ),
                                    ),
                                  ),
                                ),
                              Positioned(
                                left: _inset + travel * progress,
                                top: _inset,
                                child: _Thumb(
                                  size: thumbSize,
                                  icon: widget.icon,
                                  enabled: enabled,
                                  held: _dragging || _completing,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// The width [span] takes on one line, at the device's text scale.
double _textWidth(BuildContext context, InlineSpan span) {
  final painter = TextPainter(
    text: span,
    maxLines: 1,
    textDirection: Directionality.of(context),
    textScaler: MediaQuery.textScalerOf(context),
  )..layout();
  final width = painter.width;
  painter.dispose();
  return width;
}

/// Where [SlideActionButton] puts its label, by the room it has.
enum _LabelLayout { centred, besideChevrons, compact }

/// The round handle that is dragged along the track.
class _Thumb extends StatelessWidget {
  const _Thumb({
    required this.size,
    required this.icon,
    required this.enabled,
    required this.held,
  });

  final double size;
  final IconData icon;
  final bool enabled;

  /// Being dragged, or resting at the end: drawn with a halo.
  final bool held;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final fill = enabled
        ? colors.secondaryContainer
        : colors.secondaryContainer.withValues(alpha: 0.6);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: fill,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: colors.secondaryContainer.withValues(alpha: held ? 0.35 : 0),
            spreadRadius: held ? 4 : 0,
          ),
        ],
      ),
      child: Icon(
        icon,
        size: size * 0.5,
        color: enabled
            ? colors.onSecondaryContainer
            : colors.onSecondaryContainer.withValues(alpha: 0.6),
      ),
    );
  }
}

/// Three chevrons pointing along the track. [phase] runs from 0 to 1 as a
/// highlight sweeps across them; at 0 they are all at rest.
class _ChevronsPainter extends CustomPainter {
  const _ChevronsPainter({required this.color, required this.phase});

  final Color color;
  final double phase;

  static const int _count = 3;
  static const double _restOpacity = 0.4;

  @override
  void paint(Canvas canvas, Size size) {
    final step = size.width / _count;
    final reach = math.min(step * 0.55, size.height / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.5, size.height * 0.16)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    for (var i = 0; i < _count; i++) {
      // Each chevron lights up as the sweep passes it.
      final distance = (phase - (0.25 + i * 0.2)).abs();
      final glow = (1 - distance / 0.25).clamp(0.0, 1.0);
      paint.color = color.withValues(
        alpha: _restOpacity + (1 - _restOpacity) * glow,
      );

      final tip = Offset(step * i + step / 2 + reach / 2, size.height / 2);
      canvas.drawPath(
        Path()
          ..moveTo(tip.dx - reach, tip.dy - reach)
          ..lineTo(tip.dx, tip.dy)
          ..lineTo(tip.dx - reach, tip.dy + reach),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_ChevronsPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.phase != phase;
}
