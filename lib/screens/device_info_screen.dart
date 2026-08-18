import 'package:flutter/material.dart';

import '../models/device_snapshot.dart';
import '../services/device_info_service.dart';
import '../theme/app_colors.dart';
import '../widgets/info_section.dart';
import '../widgets/page_header.dart';

class DeviceInfoScreen extends StatefulWidget {
  /// Optional preloaded snapshot (e.g. from FullReportScreen, which already
  /// fetched one). When null, this screen loads its own.
  final DeviceSnapshot? device;

  const DeviceInfoScreen({super.key, this.device});

  @override
  State<DeviceInfoScreen> createState() => _DeviceInfoScreenState();
}

class _DeviceInfoScreenState extends State<DeviceInfoScreen> {
  DeviceSnapshot? _device;

  @override
  void initState() {
    super.initState();
    _device = widget.device;
    if (_device == null) {
      DeviceInfoService().load().then((d) {
        if (mounted) setState(() => _device = d);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = _device;
    final size = MediaQuery.of(context).size;
    final brightness = MediaQuery.of(context).platformBrightness;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
        children: [
          const PageHeader(title: 'Device info'),
          const SizedBox(height: 12),
          if (d == null)
            const Text('Loading device info…')
          else ...[
            InfoSectionCard(
              title: 'System',
              icon: Icons.memory_rounded,
              accent: AppColors.cyan,
              children: [
                InfoRow(label: 'Platform', value: d.platform),
                InfoRow(label: 'OS version', value: d.osVersion),
                InfoRow(label: 'Device model', value: d.deviceModel),
                InfoRow(label: 'Locale', value: d.locale),
              ],
            ),
            const SizedBox(height: 14),
            InfoSectionCard(
              title: 'App',
              icon: Icons.apps_rounded,
              accent: AppColors.violet,
              children: [
                InfoRow(label: 'Name', value: d.appName),
                InfoRow(label: 'Version', value: d.appVersion),
                InfoRow(label: 'Build number', value: d.buildNumber),
              ],
            ),
            const SizedBox(height: 14),
            InfoSectionCard(
              title: 'Display',
              icon: Icons.aspect_ratio_rounded,
              accent: AppColors.magenta,
              children: [
                InfoRow(label: 'Screen size', value: '${size.width.round()} × ${size.height.round()} dp'),
                InfoRow(
                  label: 'System brightness',
                  value: brightness == Brightness.dark ? 'Dark' : 'Light',
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
