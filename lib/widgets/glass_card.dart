import 'dart:ui';

import 'package:flutter/material.dart';

/// A frosted-glass surface: translucent tint + blur + a hairline border,
/// used everywhere in place of plain Material cards.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final BorderRadius borderRadius;
  final VoidCallback? onTap;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.borderRadius = const BorderRadius.all(Radius.circular(24)),
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tint = isDark ? Colors.white : Theme.of(context).colorScheme.primary;
    final borderColor = isDark ? Colors.white : Theme.of(context).colorScheme.primary;

    final content = ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: tint.withValues(alpha: isDark ? 0.05 : 0.55),
            borderRadius: borderRadius,
            border: Border.all(color: borderColor.withValues(alpha: isDark ? 0.12 : 0.15)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.06),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );

    if (onTap == null) return content;
    return Material(
      color: Colors.transparent,
      borderRadius: borderRadius,
      child: InkWell(borderRadius: borderRadius, onTap: onTap, child: content),
    );
  }
}
