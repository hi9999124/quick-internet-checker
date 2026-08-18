import 'package:flutter/material.dart';

import '../services/settings_store.dart';
import '../widgets/glass_card.dart';
import 'device_info_screen.dart';
import 'full_report_screen.dart';
import 'stats_screen.dart';

class SettingsScreen extends StatefulWidget {
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;
  final bool useMbps;
  final ValueChanged<bool> onUnitsChanged;

  const SettingsScreen({
    super.key,
    required this.themeMode,
    required this.onThemeModeChanged,
    required this.useMbps,
    required this.onUnitsChanged,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final SettingsStore _store = SettingsStore();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
        children: [
          const Text('Settings', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Appearance', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                const SizedBox(height: 8),
                _ThemeOption(
                  label: 'System default',
                  selected: widget.themeMode == ThemeMode.system,
                  onTap: () => _setTheme(ThemeMode.system),
                ),
                _ThemeOption(
                  label: 'Light',
                  selected: widget.themeMode == ThemeMode.light,
                  onTap: () => _setTheme(ThemeMode.light),
                ),
                _ThemeOption(
                  label: 'Dark',
                  selected: widget.themeMode == ThemeMode.dark,
                  onTap: () => _setTheme(ThemeMode.dark),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          GlassCard(
            child: SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text('Use Mbps', style: TextStyle(fontWeight: FontWeight.w700)),
              subtitle: const Text('Turn off to display speeds in MB/s'),
              value: widget.useMbps,
              onChanged: (value) {
                widget.onUnitsChanged(value);
                _store.saveUseMbps(value);
              },
            ),
          ),
          const SizedBox(height: 16),
          GlassCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _NavListTile(
                  icon: Icons.fact_check_rounded,
                  label: 'Full network report',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const FullReportScreen()),
                  ),
                ),
                const Divider(height: 1),
                _NavListTile(
                  icon: Icons.bar_chart_rounded,
                  label: 'Statistics',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const StatsScreen()),
                  ),
                ),
                const Divider(height: 1),
                _NavListTile(
                  icon: Icons.smartphone_rounded,
                  label: 'Device info',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const DeviceInfoScreen()),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _setTheme(ThemeMode mode) {
    widget.onThemeModeChanged(mode);
    _store.saveThemeMode(mode);
  }
}

class _NavListTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _NavListTile({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ThemeOption({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      onTap: onTap,
      leading: Icon(
        selected ? Icons.radio_button_checked_rounded : Icons.radio_button_unchecked_rounded,
        color: selected ? accent : null,
      ),
      title: Text(label),
    );
  }
}
