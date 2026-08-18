import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

enum PillTone { online, offline, warning, neutral }

/// Small glowing-dot status chip, e.g. "Online" / "Checking..." / "Offline".
class StatusPill extends StatelessWidget {
  final String label;
  final PillTone tone;

  const StatusPill({super.key, required this.label, required this.tone});

  Color get _color {
    switch (tone) {
      case PillTone.online:
        return AppColors.online;
      case PillTone.offline:
        return AppColors.offline;
      case PillTone.warning:
        return AppColors.warning;
      case PillTone.neutral:
        return AppColors.cyan;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              boxShadow: [BoxShadow(color: color.withValues(alpha: 0.9), blurRadius: 8, spreadRadius: 1)],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
