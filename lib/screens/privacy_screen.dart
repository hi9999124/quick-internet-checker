import 'package:flutter/material.dart';

import '../models/privacy_signals.dart';
import '../models/speed_sample.dart';
import '../theme/app_colors.dart';
import '../widgets/glass_card.dart';
import '../widgets/info_section.dart';

class PrivacyScreen extends StatelessWidget {
  final PrivacySignals signals;
  final IpInfo? ip;

  const PrivacyScreen({super.key, required this.signals, required this.ip});

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6);
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.arrow_back_rounded),
              ),
              const Text('Privacy', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              'These are client-side signals only — QIC has no server backend, '
              'so nothing here is a definitive detector. Treat it as a hint, not proof.',
              style: TextStyle(fontSize: 13, color: muted),
            ),
          ),
          const SizedBox(height: 16),

          InfoSectionCard(
            title: 'VPN / hosting heuristic',
            icon: Icons.vpn_key_rounded,
            accent: signals.possibleVpnOrHosting ? AppColors.warning : AppColors.online,
            children: [
              InfoRow(
                label: 'Result',
                value: signals.possibleVpnOrHosting ? 'Possible VPN / hosting IP' : 'No signal detected',
                valueColor: signals.possibleVpnOrHosting ? AppColors.warning : AppColors.online,
              ),
              const SizedBox(height: 6),
              Text(signals.vpnReason, style: TextStyle(fontSize: 13, color: muted)),
            ],
          ),
          const SizedBox(height: 14),

          InfoSectionCard(
            title: 'IP exposure',
            icon: Icons.visibility_outlined,
            accent: AppColors.magenta,
            children: [
              InfoRow(label: 'Public IP visible to sites you visit', value: ip?.ip ?? 'Unknown'),
              InfoRow(label: 'Approximate location derived from it', value: ip?.location ?? 'Unknown'),
              InfoRow(label: 'Local network IP', value: signals.localIPv4 ?? 'Not exposed on this platform'),
              InfoRow(label: 'IPv6 reachable', value: signals.ipv6Supported ? 'Yes' : 'No / unknown'),
            ],
          ),
          const SizedBox(height: 14),

          InfoSectionCard(
            title: 'DNS privacy',
            icon: Icons.dns_rounded,
            accent: AppColors.violet,
            children: const [
              Text(
                'Unless your device uses encrypted DNS (DNS-over-HTTPS or '
                'DNS-over-TLS), your network operator or ISP can typically see '
                'which domain names you resolve, even over an HTTPS connection.',
              ),
            ],
          ),
          const SizedBox(height: 14),

          GlassCard(
            child: Row(
              children: [
                Icon(Icons.lock_rounded, color: AppColors.online),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text('QIC only talks to its speed-test, IP-lookup, and ping targets over HTTPS.'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
