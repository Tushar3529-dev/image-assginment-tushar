import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import '../core/app_motion.dart';
import '../core/app_theme.dart';

/// A tappable rounded box with a dashed border (CustomPainter, no package).
/// With [animate], the dashes slowly march around the border; the box also
/// presses in slightly while touched.
class DashedBorderBox extends StatefulWidget {
  const DashedBorderBox({
    super.key,
    required this.child,
    this.height,
    this.color = AppColors.primary,
    this.fillColor,
    this.radius = 12,
    this.strokeWidth = 1.5,
    this.dash = 6,
    this.gap = 4,
    this.animate = false,
    this.onTap,
  });

  final Widget child;
  final double? height;
  final Color color;
  final Color? fillColor;
  final double radius;
  final double strokeWidth;
  final double dash;
  final double gap;
  final bool animate;
  final VoidCallback? onTap;

  @override
  State<DashedBorderBox> createState() => _DashedBorderBoxState();
}

class _DashedBorderBoxState extends State<DashedBorderBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _march = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );
  bool _pressed = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncMarch();
  }

  @override
  void didUpdateWidget(DashedBorderBox oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncMarch();
  }

  void _syncMarch() {
    if (widget.animate && !AppMotion.reduced(context)) {
      if (!_march.isAnimating) _march.repeat();
    } else {
      _march.stop();
    }
  }

  @override
  void dispose() {
    _march.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shape = BorderRadius.circular(widget.radius);
    return AnimatedScale(
      scale: _pressed ? 0.97 : 1,
      duration: AppMotion.of(context, AppMotion.fast),
      curve: Curves.easeOut,
      child: SizedBox(
        height: widget.height,
        width: double.infinity,
        child: CustomPaint(
          painter: _DashedRRectPainter(
            color: widget.color,
            fill: widget.fillColor,
            radius: widget.radius,
            strokeWidth: widget.strokeWidth,
            dash: widget.dash,
            gap: widget.gap,
            phase: _march,
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: shape,
            child: InkWell(
              borderRadius: shape,
              onTap: widget.onTap,
              onHighlightChanged: (value) => setState(() => _pressed = value),
              child: Center(child: widget.child),
            ),
          ),
        ),
      ),
    );
  }
}

class _DashedRRectPainter extends CustomPainter {
  _DashedRRectPainter({
    required this.color,
    required this.fill,
    required this.radius,
    required this.strokeWidth,
    required this.dash,
    required this.gap,
    required this.phase,
  }) : super(repaint: phase);

  final Color color;
  final Color? fill;
  final double radius;
  final double strokeWidth;
  final double dash;
  final double gap;
  final Animation<double> phase;

  @override
  void paint(Canvas canvas, Size size) {
    final inset = strokeWidth / 2;
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        inset,
        inset,
        size.width - strokeWidth,
        size.height - strokeWidth,
      ),
      Radius.circular(radius),
    );
    if (fill != null) canvas.drawRRect(rrect, Paint()..color = fill!);

    final period = dash + gap;
    final dashed = Path();
    for (final PathMetric metric
        in (Path()..addRRect(rrect)).computeMetrics()) {
      // Shift every dash forward by the current phase so they "march".
      var distance = phase.value * period - period;
      while (distance < metric.length) {
        final start = math.max(distance, 0.0);
        final end = math.min(distance + dash, metric.length);
        if (end > start) {
          dashed.addPath(metric.extractPath(start, end), Offset.zero);
        }
        distance += period;
      }
    }
    canvas.drawPath(
      dashed,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
    );
  }

  @override
  bool shouldRepaint(_DashedRRectPainter old) =>
      old.color != color ||
      old.fill != fill ||
      old.radius != radius ||
      old.strokeWidth != strokeWidth ||
      old.dash != dash ||
      old.gap != gap ||
      old.phase != phase;
}

/// A thin horizontal dashed line.
class DashedLine extends StatelessWidget {
  const DashedLine({super.key, this.color = const Color(0xFFBDBDBD)});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(double.infinity, 1),
      painter: _DashedLinePainter(color),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  _DashedLinePainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    var x = 0.0;
    while (x < size.width) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(math.min(x + 5, size.width), 0),
        paint,
      );
      x += 9;
    }
  }

  @override
  bool shouldRepaint(_DashedLinePainter old) => old.color != color;
}
