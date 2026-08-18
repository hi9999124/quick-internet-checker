import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'about_screen.dart';
import 'history_screen.dart';
import 'home_screen.dart';
import 'network_info_screen.dart';
import 'settings_screen.dart';

class RootShell extends StatefulWidget {
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;
  final bool useMbps;
  final ValueChanged<bool> onUnitsChanged;

  const RootShell({
    super.key,
    required this.themeMode,
    required this.onThemeModeChanged,
    required this.useMbps,
    required this.onUnitsChanged,
  });

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final screens = [
      const HomeScreen(),
      const NetworkInfoScreen(),
      const HistoryScreen(),
      SettingsScreen(
        themeMode: widget.themeMode,
        onThemeModeChanged: widget.onThemeModeChanged,
        useMbps: widget.useMbps,
        onUnitsChanged: widget.onUnitsChanged,
      ),
      const AboutScreen(),
    ];

    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.transparent,
      body: IndexedStack(index: _index, children: screens),
      bottomNavigationBar: _GlassNavBar(
        index: _index,
        onChanged: (i) => setState(() => _index = i),
      ),
    );
  }
}

class _GlassNavBar extends StatelessWidget {
  final int index;
  final ValueChanged<int> onChanged;

  const _GlassNavBar({required this.index, required this.onChanged});

  static const _items = [
    (Icons.speed_rounded, 'Test'),
    (Icons.public_rounded, 'Network'),
    (Icons.history_rounded, 'History'),
    (Icons.tune_rounded, 'Settings'),
    (Icons.info_outline_rounded, 'About'),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            height: 68,
            decoration: BoxDecoration(
              color: (isDark ? Colors.white : Theme.of(context).colorScheme.primary)
                  .withValues(alpha: isDark ? 0.06 : 0.5),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: (isDark ? Colors.white : Theme.of(context).colorScheme.primary).withValues(alpha: 0.14),
              ),
            ),
            child: Row(
              children: List.generate(_items.length, (i) {
                final selected = i == index;
                final (icon, label) = _items[i];
                return Expanded(
                  child: InkWell(
                    onTap: () => onChanged(i),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(icon, size: 22, color: selected ? AppColors.cyan : null),
                        const SizedBox(height: 2),
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                            color: selected ? AppColors.cyan : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}
