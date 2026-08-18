import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Shown when a screen is displaying a previously-cached result instead of
/// a fresh live one — the app's "works offline" affordance.
class CacheBadge extends StatelessWidget {
  final DateTime since;

  const CacheBadge({super.key, required this.since});

  String _relative() {
    final diff = DateTime.now().difference(since);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cloud_off_rounded, size: 13, color: AppColors.warning),
          const SizedBox(width: 5),
          Text(
            'Cached ${_relative()}',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.warning),
          ),
        ],
      ),
    );
  }
}
