import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/history_stats.dart';
import '../models/speed_sample.dart';
import '../services/history_store.dart';
import '../theme/app_colors.dart';
import '../widgets/info_section.dart';
import '../widgets/sparkline.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  final HistoryStore _history = HistoryStore();
  List<SpeedSample> _samples = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final samples = await _history.load();
    if (!mounted) return;
    setState(() {
      _samples = samples;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final stats = HistoryStats.fromSamples(_samples);
    final chronological = _samples.reversed.toList();

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
              const Text('Statistics', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 12),
          if (_loading)
            const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
          else if (stats.totalTests == 0)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text('Run a speed test to start building statistics.'),
            )
          else ...[
            if (chronological.length > 1)
              InfoSectionCard(
                title: 'Download trend (Mbps)',
                icon: Icons.show_chart_rounded,
                accent: AppColors.cyan,
                children: [Sparkline(values: chronological.map((s) => s.downloadMbps).toList())],
              ),
            const SizedBox(height: 14),
            InfoSectionCard(
              title: 'Totals',
              icon: Icons.summarize_rounded,
              accent: AppColors.violet,
              children: [
                InfoRow(label: 'Total tests run', value: '${stats.totalTests}'),
                InfoRow(label: 'Tests today', value: '${stats.testsToday}'),
                InfoRow(
                  label: 'Tracking since',
                  value: stats.firstTestAt == null ? '—' : DateFormat('MMM d, y').format(stats.firstTestAt!),
                ),
              ],
            ),
            const SizedBox(height: 14),
            InfoSectionCard(
              title: 'Averages',
              icon: Icons.equalizer_rounded,
              accent: AppColors.magenta,
              children: [
                InfoRow(label: 'Average download', value: '${stats.avgDownloadMbps.toStringAsFixed(1)} Mbps'),
                InfoRow(label: 'Average upload', value: '${stats.avgUploadMbps.toStringAsFixed(1)} Mbps'),
                InfoRow(label: 'Average ping', value: '${stats.avgPingMs.toStringAsFixed(0)} ms'),
              ],
            ),
            const SizedBox(height: 14),
            InfoSectionCard(
              title: 'Bests',
              icon: Icons.emoji_events_rounded,
              accent: AppColors.online,
              children: [
                InfoRow(label: 'Best download', value: '${stats.bestDownloadMbps.toStringAsFixed(1)} Mbps'),
                InfoRow(label: 'Best (lowest) ping', value: '${stats.bestPingMs} ms'),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
