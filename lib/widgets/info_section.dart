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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 18, color: accent ?? Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 8),
                  ],
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                ],
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const InfoRow({super.key, required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6))),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(fontWeight: FontWeight.w600, color: valueColor),
            ),
          ),
        ],
      ),
    );
  }
}
