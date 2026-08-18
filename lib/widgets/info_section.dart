import 'package:flutter/material.dart';

import 'glass_card.dart';

/// A titled glass card holding a list of [InfoRow]s — the building block
/// for the detail-heavy report/privacy/device/stats screens.
class InfoSectionCard extends StatelessWidget {
  final String title;
  final IconData? icon;
  final Color? accent;
  final List<Widget> children;
  final Widget? trailing;

  const InfoSectionCard({
    super.key,
    required this.title,
    required this.children,
    this.icon,
    this.accent,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: accent ?? Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
              ],
              // Flexible so a long title wraps instead of shoving the
              // trailing widget off the edge at large font scales.
              Flexible(
                child: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 8),
                trailing!,
              ],
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

/// A label/value pair. Both sides sit on one line when they fit; when the
/// system font scale (or a long value) makes that impossible, the value
/// drops onto its own line instead of being clipped or hyphenated mid-word.
class InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const InfoRow({super.key, required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    final labelStyle = TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6));
    final valueStyle = TextStyle(fontWeight: FontWeight.w600, color: valueColor);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxWidth = constraints.maxWidth;
          final textScaler = MediaQuery.textScalerOf(context);
          final labelWidth = _measure(label, labelStyle, textScaler, context);
          final valueWidth = _measure(value, valueStyle, textScaler, context);
          final fitsOnOneLine = labelWidth + valueWidth + 12 <= maxWidth;

          if (fitsOnOneLine) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(child: Text(label, style: labelStyle)),
                const SizedBox(width: 12),
                Flexible(child: Text(value, textAlign: TextAlign.right, style: valueStyle)),
              ],
            );
          }

          // Stacked: label above, value below — both free to wrap over as
          // many lines as they need.
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: labelStyle),
              const SizedBox(height: 2),
              Text(value, style: valueStyle),
            ],
          );
        },
      ),
    );
  }

  double _measure(String text, TextStyle style, TextScaler scaler, BuildContext context) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: DefaultTextStyle.of(context).style.merge(style)),
      textDirection: Directionality.of(context),
      textScaler: scaler,
      maxLines: 1,
    )..layout();
    return painter.size.width;
  }
}
