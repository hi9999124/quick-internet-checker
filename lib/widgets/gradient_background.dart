import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Full-screen backdrop with slow-drifting blurred accent orbs, matching
/// the QIC brand palette. Sits behind every screen via [AppShellBackground].
class GradientBackground extends StatefulWidget {
  final Widget child;
  const GradientBackground({super.key, required this.child});

  @override
  State<GradientBackground> createState() => _GradientBackgroundState();
}

class _GradientBackgroundState extends State<GradientBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 24),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? AppColors.darkBg : AppColors.lightBg;

    return Stack(
      children: [
        Container(color: baseColor),
        AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return CustomPaint(
              size: Size.infinite,
              painter: _OrbPainter(t: _controller.value, isDark: isDark),
            );
          },
        ),
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
          child: Container(color: Colors.transparent),
        ),
        widget.child,
      ],
    );
  }
}

class _OrbPainter extends CustomPainter {
  final double t;
  final bool isDark;
  _OrbPainter({required this.t, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final opacity = isDark ? 0.55 : 0.30;
    final orbs = [
      (AppColors.cyan, Offset(0.2 + 0.1 * sin(t * 2 * pi), 0.25 + 0.08 * cos(t * 2 * pi)), 0.55),
      (AppColors.violet, Offset(0.8 - 0.12 * cos(t * 2 * pi), 0.65 + 0.1 * sin(t * 2 * pi)), 0.6),
      (AppColors.magenta, Offset(0.5 + 0.08 * sin(t * 2 * pi + 1.5), 0.85 - 0.08 * cos(t * 2 * pi)), 0.4),
    ];

    for (final (color, offset, radiusFactor) in orbs) {
      final center = Offset(size.width * offset.dx, size.height * offset.dy);
      final radius = size.shortestSide * radiusFactor;
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [color.withValues(alpha: opacity), color.withValues(alpha: 0)],
        ).createShader(Rect.fromCircle(center: center, radius: radius));
      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _OrbPainter oldDelegate) => oldDelegate.t != t;
}
