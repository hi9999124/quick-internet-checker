import 'package:intl/intl.dart';
import 'package:flutter/material.dart';

import '../models/speed_sample.dart';
import '../services/history_store.dart';
import '../theme/app_colors.dart';
import '../widgets/glass_card.dart';
import '../widgets/sparkline.dart';
import 'stats_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final HistoryStore _store = HistoryStore();
  List<SpeedSample> _entries = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
    HistoryStore.changes.addListener(_load);
  }

  @override
  void dispose() {
    HistoryStore.changes.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    final entries = await _store.load();
    if (!mounted) return;
    setState(() {
      _entries = entries;
      _loading = false;
    });
  }

  Future<void> _clearAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear history?'),
        content: const Text('This removes every saved test result. This can\'t be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Clear')),
        ],
      ),
    );
    if (confirmed == true) {
      await _store.clear();
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_entries.isEmpty) {
      return SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.history_rounded, size: 56, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3)),
              const SizedBox(height: 12),
              Text('No tests yet', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6))),
            ],
          ),
        ),
      );
    }

    final chronological = _entries.reversed.toList();
    final downloadSeries = chronological.map((e) => e.downloadMbps).toList();

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('History', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const StatsScreen()),
                    ),
                    icon: const Icon(Icons.bar_chart_rounded),
                    tooltip: 'Statistics',
                  ),
                  IconButton(
                    onPressed: _clearAll,
                    icon: const Icon(Icons.delete_outline_rounded),
                    tooltip: 'Clear history',
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (downloadSeries.length > 1)
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Download trend (Mbps)', style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  Sparkline(values: downloadSeries),
                ],
              ),
            ),
          const SizedBox(height: 16),
          ..._entries.map((entry) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: GlassCard(
                  borderRadius: BorderRadius.circular(18),
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              DateFormat('MMM d, y • HH:mm').format(entry.timestamp),
                              style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55)),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(Icons.arrow_downward_rounded, size: 16, color: AppColors.cyan),
                                Text(' ${entry.downloadMbps.toStringAsFixed(1)} Mbps   '),
                                Icon(Icons.arrow_upward_rounded, size: 16, color: AppColors.violet),
                                Text(' ${entry.uploadMbps.toStringAsFixed(1)} Mbps'),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('${entry.pingMs} ms', style: const TextStyle(fontWeight: FontWeight.w700)),
                          Text('ping', style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5))),
                        ],
                      ),
                    ],
                  ),
                ),
              )),
        ],
      ),
    );
  }
}
