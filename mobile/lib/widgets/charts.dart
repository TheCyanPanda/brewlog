// Lightweight charts drawn with CustomPainter (no chart library).
//
// ScatterChart: x/y points with optional trend line, y axis can show the
//               5 rating levels.
// MiniBars:     vertical bars, e.g. brews per week.
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme.dart';
import '../utils/format.dart';

class ScatterPoint {
  final double x;
  final double y;
  final Color? color;
  const ScatterPoint(this.x, this.y, {this.color});
}

class ScatterChart extends StatelessWidget {
  final List<ScatterPoint> points;
  final String xLabel;
  final bool ratingAxis;        // y = 1..5 rating scale with labels
  final bool showTrend;         // fitted curve through per-x averages
  final double height;
  final String Function(double)? formatX;
  final double? highlightX;     // vertical marker, e.g. the suggested grind

  const ScatterChart({
    super.key,
    required this.points,
    required this.xLabel,
    this.ratingAxis = true,
    this.showTrend = true,
    this.height = 200,
    this.formatX,
    this.highlightX,
  });

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return SizedBox(
        height: height,
        child: const Center(child: Text('Not enough data yet', style: TextStyle(color: BrewColors.muted))),
      );
    }
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _ScatterPainter(
          points: points,
          xLabel: xLabel,
          ratingAxis: ratingAxis,
          showTrend: showTrend,
          formatX: formatX ?? (double v) => formatNum(v),
          highlightX: highlightX,
        ),
      ),
    );
  }
}

class _ScatterPainter extends CustomPainter {
  final List<ScatterPoint> points;
  final String xLabel;
  final bool ratingAxis;
  final bool showTrend;
  final String Function(double) formatX;
  final double? highlightX;

  _ScatterPainter({
    required this.points,
    required this.xLabel,
    required this.ratingAxis,
    required this.showTrend,
    required this.formatX,
    required this.highlightX,
  });

  static const TextStyle _axis = TextStyle(color: BrewColors.muted, fontSize: 10.5);

  void _text(Canvas canvas, String s, Offset at, {TextAlign align = TextAlign.left, TextStyle style = _axis}) {
    final TextPainter tp = TextPainter(text: TextSpan(text: s, style: style), textDirection: TextDirection.ltr)..layout();
    double dx = at.dx;
    if (align == TextAlign.center) dx -= tp.width / 2;
    if (align == TextAlign.right) dx -= tp.width;
    tp.paint(canvas, Offset(dx, at.dy - tp.height / 2));
  }

  @override
  void paint(Canvas canvas, Size size) {
    final double left = ratingAxis ? 62 : 32;
    const double bottom = 34;
    const double top = 8;
    const double right = 10;
    final Rect plot = Rect.fromLTRB(left, top, size.width - right, size.height - bottom);

    double minX = points.map((ScatterPoint p) => p.x).reduce(math.min);
    double maxX = points.map((ScatterPoint p) => p.x).reduce(math.max);
    if (highlightX != null) {
      minX = math.min(minX, highlightX!);
      maxX = math.max(maxX, highlightX!);
    }
    if (maxX - minX < 1e-6) {
      minX -= 1;
      maxX += 1;
    }
    final double padX = (maxX - minX) * 0.08;
    minX -= padX;
    maxX += padX;

    double minY = ratingAxis ? 0.6 : points.map((ScatterPoint p) => p.y).reduce(math.min);
    double maxY = ratingAxis ? 5.4 : points.map((ScatterPoint p) => p.y).reduce(math.max);
    if (maxY - minY < 1e-6) {
      minY -= 1;
      maxY += 1;
    }

    Offset map(double x, double y) => Offset(
          plot.left + (x - minX) / (maxX - minX) * plot.width,
          plot.bottom - (y - minY) / (maxY - minY) * plot.height,
        );

    // Grid + y labels
    final Paint grid = Paint()
      ..color = BrewColors.outline.withValues(alpha: 0.5)
      ..strokeWidth = 1;
    if (ratingAxis) {
      for (int r = 1; r <= 5; r++) {
        final double y = map(minX, r.toDouble()).dy;
        canvas.drawLine(Offset(plot.left, y), Offset(plot.right, y), grid);
        _text(canvas, ratingLabel(kRatings[r - 1]), Offset(plot.left - 8, y), align: TextAlign.right,
            style: _axis.copyWith(color: ratingColor(kRatings[r - 1]).withValues(alpha: 0.9)));
      }
    } else {
      for (int i = 0; i <= 3; i++) {
        final double v = minY + (maxY - minY) * i / 3;
        final double y = map(minX, v).dy;
        canvas.drawLine(Offset(plot.left, y), Offset(plot.right, y), grid);
        _text(canvas, formatNum(v), Offset(plot.left - 6, y), align: TextAlign.right);
      }
    }

    // X ticks
    for (int i = 0; i <= 4; i++) {
      final double v = minX + padX + (maxX - minX - 2 * padX) * i / 4;
      _text(canvas, formatX(v), Offset(map(v, minY).dx, plot.bottom + 10), align: TextAlign.center);
    }
    _text(canvas, xLabel, Offset(plot.center.dx, size.height - 8), align: TextAlign.center,
        style: _axis.copyWith(fontWeight: FontWeight.w600));

    // Highlight marker
    if (highlightX != null) {
      final double x = map(highlightX!, minY).dx;
      final Paint hl = Paint()
        ..color = BrewColors.sage.withValues(alpha: 0.7)
        ..strokeWidth = 2;
      for (double y = plot.top; y < plot.bottom; y += 8) {
        canvas.drawLine(Offset(x, y), Offset(x, math.min(y + 4, plot.bottom)), hl);
      }
    }

    // Trend: average y per x bucket, smoothed line
    if (showTrend && points.length >= 3) {
      final Map<double, List<double>> buckets = <double, List<double>>{};
      final double bucket = (maxX - minX - 2 * padX) / 8;
      for (final ScatterPoint p in points) {
        final double k = bucket <= 0 ? p.x : (p.x / bucket).round() * bucket;
        (buckets[k] ??= <double>[]).add(p.y);
      }
      final List<double> xs = buckets.keys.toList()..sort();
      if (xs.length >= 2) {
        final Path path = Path();
        for (int i = 0; i < xs.length; i++) {
          final List<double> ys = buckets[xs[i]]!;
          final Offset o = map(xs[i], ys.reduce((double a, double b) => a + b) / ys.length);
          if (i == 0) {
            path.moveTo(o.dx, o.dy);
          } else {
            path.lineTo(o.dx, o.dy);
          }
        }
        canvas.drawPath(
          path,
          Paint()
            ..color = BrewColors.caramel.withValues(alpha: 0.55)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.5
            ..strokeJoin = StrokeJoin.round
            ..strokeCap = StrokeCap.round,
        );
      }
    }

    // Points (slight vertical jitter on the rating axis so overlaps show)
    for (int i = 0; i < points.length; i++) {
      final ScatterPoint p = points[i];
      final double jitter = ratingAxis ? (((i * 37) % 7) - 3) * 0.035 : 0;
      final Color c = p.color ?? (ratingAxis ? ratingColor(kRatings[(p.y.round() - 1).clamp(0, 4)]) : BrewColors.caramel);
      final Offset o = map(p.x, p.y + jitter);
      canvas.drawCircle(o, 5.5, Paint()..color = c.withValues(alpha: 0.85));
      canvas.drawCircle(o, 5.5, Paint()
        ..color = BrewColors.card
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2);
    }
  }

  @override
  bool shouldRepaint(covariant _ScatterPainter old) => old.points != points || old.highlightX != highlightX;
}

// Simple vertical bar chart with labels under each bar
class MiniBars extends StatelessWidget {
  final List<double> values;
  final List<String> labels;
  final double height;
  final Color color;
  final int? highlightIndex;

  const MiniBars({
    super.key,
    required this.values,
    required this.labels,
    this.height = 120,
    this.color = BrewColors.caramel,
    this.highlightIndex,
  });

  @override
  Widget build(BuildContext context) {
    final double maxV = values.isEmpty ? 1 : math.max(1, values.reduce(math.max));
    return SizedBox(
      height: height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          for (int i = 0; i < values.length; i++)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: <Widget>[
                    if (values[i] > 0)
                      Text(formatNum(values[i]), style: const TextStyle(fontSize: 10, color: BrewColors.muted)),
                    const SizedBox(height: 3),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeOutCubic,
                      height: math.max(3, (height - 36) * values[i] / maxV),
                      decoration: BoxDecoration(
                        color: (highlightIndex == null || highlightIndex == i) ? color : color.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      labels[i],
                      maxLines: 1,
                      overflow: TextOverflow.clip,
                      style: const TextStyle(fontSize: 10.5, color: BrewColors.muted),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
