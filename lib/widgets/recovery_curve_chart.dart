import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/heart_rate_sample.dart';

class RecoveryCurveChart extends StatelessWidget {
  const RecoveryCurveChart({
    super.key,
    required this.samples,
    required this.recoveryStartedAt,
    this.height = 180,
  });

  final List<HeartRateSample> samples;
  final DateTime recoveryStartedAt;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (samples.length < 2) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _RecoveryCurvePainter(
          samples: samples,
          recoveryStartedAt: recoveryStartedAt,
          textStyle:
              Theme.of(context).textTheme.bodySmall ?? const TextStyle(fontSize: 11),
          lineColor: Theme.of(context).colorScheme.primary,
          gridColor: Theme.of(context).dividerColor,
        ),
      ),
    );
  }
}

class _RecoveryCurvePainter extends CustomPainter {
  _RecoveryCurvePainter({
    required this.samples,
    required this.recoveryStartedAt,
    required this.textStyle,
    required this.lineColor,
    required this.gridColor,
  });

  final List<HeartRateSample> samples;
  final DateTime recoveryStartedAt;
  final TextStyle textStyle;
  final Color lineColor;
  final Color gridColor;

  @override
  void paint(Canvas canvas, Size size) {
    final sortedSamples = [...samples]
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    final recoveryWindowSamples = sortedSamples.where((sample) {
      final seconds =
          sample.timestamp.difference(recoveryStartedAt).inMilliseconds / 1000.0;
      return seconds >= -30 && seconds <= 130;
    }).toList();

    final displaySamples = recoveryWindowSamples.length >= 2
        ? recoveryWindowSamples
        : sortedSamples;

    if (displaySamples.length < 2) return;

    final leftPadding = 36.0;
    final rightPadding = 12.0;
    final topPadding = 12.0;
    final bottomPadding = 28.0;

    final chartRect = Rect.fromLTWH(
      leftPadding,
      topPadding,
      size.width - leftPadding - rightPadding,
      size.height - topPadding - bottomPadding,
    );

    final minHr = displaySamples.map((s) => s.bpm).reduce(math.min);
    final maxHr = displaySamples.map((s) => s.bpm).reduce(math.max);

    final yMin = ((minHr - 5) ~/ 5) * 5;
    final yMax = (((maxHr + 5) + 4) ~/ 5) * 5;
    final yRange = math.max(1, yMax - yMin);

    double secondsFromRecoveryStart(HeartRateSample sample) {
      return sample.timestamp
              .difference(recoveryStartedAt)
              .inMilliseconds /
          1000.0;
    }

    double xForSample(HeartRateSample sample) {
      final seconds = secondsFromRecoveryStart(sample);
      final clamped = seconds.clamp(0.0, 120.0);
      return chartRect.left + chartRect.width * (clamped / 120.0);
    }

    double yForHr(int bpm) {
      return chartRect.bottom -
          chartRect.height * ((bpm - yMin).toDouble() / yRange);
    }

    final axisPaint = Paint()
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke
      ..color = gridColor.withOpacity(0.7);

    final gridPaint = Paint()
      ..strokeWidth = 0.6
      ..style = PaintingStyle.stroke
      ..color = gridColor.withOpacity(0.35);

    final linePaint = Paint()
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = lineColor;

    final pointPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = lineColor;

    canvas.drawRect(chartRect, axisPaint);

    for (final second in [0, 60, 120]) {
      final x = chartRect.left + chartRect.width * (second / 120.0);
      canvas.drawLine(
        Offset(x, chartRect.top),
        Offset(x, chartRect.bottom),
        gridPaint,
      );

      _drawText(
        canvas,
        '$second s',
        Offset(x - 12, chartRect.bottom + 8),
        textStyle,
      );
    }

    final midHr = ((yMin + yMax) / 2).round();

    for (final hr in [yMin, midHr, yMax]) {
      final y = yForHr(hr);
      canvas.drawLine(
        Offset(chartRect.left, y),
        Offset(chartRect.right, y),
        gridPaint,
      );

      _drawText(
        canvas,
        '$hr',
        Offset(4, y - 7),
        textStyle,
      );
    }

    final points = displaySamples.map((sample) {
      return Offset(xForSample(sample), yForHr(sample.bpm));
    }).toList();

    final path = Path()..moveTo(points.first.dx, points.first.dy);

    // Smooth visual curve only. Raw samples remain unchanged.
    for (var i = 1; i < points.length; i++) {
      final previous = points[i - 1];
      final current = points[i];
      final controlX = (previous.dx + current.dx) / 2;

      path.cubicTo(
        controlX,
        previous.dy,
        controlX,
        current.dy,
        current.dx,
        current.dy,
      );
    }

    canvas.drawPath(path, linePaint);

    for (final point in points) {
      canvas.drawCircle(point, 2.5, pointPaint);
    }

    _drawText(
      canvas,
      'BPM',
      Offset(4, chartRect.top - 2),
      textStyle,
    );
  }

  void _drawText(
    Canvas canvas,
    String text,
    Offset offset,
    TextStyle style,
  ) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    );

    painter.layout();
    painter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant _RecoveryCurvePainter oldDelegate) {
    return oldDelegate.samples != samples ||
        oldDelegate.recoveryStartedAt != recoveryStartedAt ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.gridColor != gridColor;
  }
}