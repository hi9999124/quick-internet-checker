import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../widgets/glass_card.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
        children: [
          const Text('About', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          GlassCard(
            child: Column(
              children: [
                ShaderMask(
                  shaderCallback: (rect) => AppColors.primaryGradient.createShader(rect),
                  child: const Text(
                    'QIC',
                    style: TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 6),
                const Text('Quick Internet Checker', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(
                  'Version 1.0.0',
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55)),
                ),
                const SizedBox(height: 16),
                const Text(
                  'QIC checks your internet speed, availability, latency, DNS health, '
                  'and public IP/ISP details — on Android, web, and desktop, from one codebase.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Built with', style: TextStyle(fontWeight: FontWeight.w700)),
                SizedBox(height: 8),
                Text('• Flutter — shared Android / web / desktop codebase'),
                Text('• Cloudflare speed test endpoints for download/upload'),
                Text('• ipapi.co for public IP & ISP lookups'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
