import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class Sparkline extends StatelessWidget {
  final List<double> values;
  final double height;

  const Sparkline({super.key, required this.values, this.height = 60});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(painter: _SparklinePainter(values)),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final List<double> values;
  _SparklinePainter(this.values);

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;
    final maxV = values.reduce((a, b) => a > b ? a : b);
    final minV = values.reduce((a, b) => a < b ? a : b);
    final range = (maxV - minV).abs() < 0.001 ? 1 : maxV - minV;

    final path = Path();
    final fillPath = Path();
    for (var i = 0; i < values.length; i++) {
      final x = size.width * (i / (values.length - 1));
      final normalized = (values[i] - minV) / range;
      final y = size.height - (normalized * size.height);
      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }
    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [AppColors.cyan.withValues(alpha: 0.35), AppColors.cyan.withValues(alpha: 0)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(fillPath, fillPaint);

    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..shader = AppColors.speedGradient.createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) => oldDelegate.values != values;
}
