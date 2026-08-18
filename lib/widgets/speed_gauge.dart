import 'dart:math';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Circular speedometer-style gauge. [value] is the current reading in
/// Mbps; [maxValue] sets the scale (auto-grows as [value] passes it).
class SpeedGauge extends StatelessWidget {
  final double value;
  final double maxValue;
  final String unitLabel;
  final String centerCaption;

  const SpeedGauge({
    super.key,
    required this.value,
    required this.maxValue,
    this.unitLabel = 'Mbps',
    this.centerCaption = '',
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value),
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
      builder: (context, animatedValue, _) {
        return CustomPaint(
          painter: _GaugePainter(
            value: animatedValue,
            maxValue: maxValue <= 0 ? 1 : maxValue,
            isDark: isDark,
          ),
          child: SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    animatedValue.toStringAsFixed(animatedValue < 10 ? 2 : 1),
                    style: TextStyle(
                      fontSize: 46,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF10182B),
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    unitLabel,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.cyan,
                      letterSpacing: 1.2,
                    ),
                  ),
                  if (centerCaption.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      centerCaption,
                      style: TextStyle(
                        fontSize: 12,
                        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.55),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double value;
  final double maxValue;
  final bool isDark;

  _GaugePainter({required this.value, required this.maxValue, required this.isDark});

  static const double _startAngle = 0.75 * pi;
  static const double _sweepAngle = 1.5 * pi;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2 - 14;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round
      ..color = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08);
    canvas.drawArc(rect, _startAngle, _sweepAngle, false, trackPaint);

    final fraction = (value / maxValue).clamp(0.0, 1.0);
    final progressPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round
      ..shader = AppColors.speedGradient.createShader(rect);
    canvas.drawArc(rect, _startAngle, _sweepAngle * fraction, false, progressPaint);

    // Glow dot at the current tip.
    final tipAngle = _startAngle + _sweepAngle * fraction;
    final tip = Offset(center.dx + radius * cos(tipAngle), center.dy + radius * sin(tipAngle));
    final glowPaint = Paint()
      ..color = AppColors.cyanBright.withValues(alpha: 0.9)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(tip, 7, glowPaint);
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) =>
      oldDelegate.value != value || oldDelegate.maxValue != maxValue || oldDelegate.isDark != isDark;
}
