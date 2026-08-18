import 'package:flutter/material.dart';

import 'screens/root_shell.dart';
import 'services/settings_store.dart';
import 'theme/app_theme.dart';
import 'widgets/gradient_background.dart';

class QicApp extends StatefulWidget {
  const QicApp({super.key});

  @override
  State<QicApp> createState() => _QicAppState();
}

class _QicAppState extends State<QicApp> {
  final SettingsStore _settings = SettingsStore();
  ThemeMode _themeMode = ThemeMode.system;
  bool _useMbps = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final mode = await _settings.loadThemeMode();
    final useMbps = await _settings.loadUseMbps();
    if (!mounted) return;
    setState(() {
      _themeMode = mode;
      _useMbps = useMbps;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QIC — Quick Internet Checker',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      builder: (context, child) => GradientBackground(child: child ?? const SizedBox.shrink()),
      home: RootShell(
        themeMode: _themeMode,
        onThemeModeChanged: (mode) => setState(() => _themeMode = mode),
        useMbps: _useMbps,
        onUnitsChanged: (value) => setState(() => _useMbps = value),
      ),
    );
  }
}
