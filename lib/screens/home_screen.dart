import 'package:flutter/material.dart';

import '../models/speed_sample.dart';
import '../services/history_store.dart';
import '../services/network_service.dart';
import '../theme/app_colors.dart';
import '../widgets/glass_card.dart';
import '../widgets/metric_tile.dart';
import '../widgets/speed_gauge.dart';
import '../widgets/status_pill.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final NetworkService _network = NetworkService();
  final HistoryStore _history = HistoryStore();

  bool _isTesting = false;
  SpeedTestStage _stage = SpeedTestStage.idle;
  double _gaugeValue = 0;
  double _gaugeMax = 100;
  SpeedSample? _lastResult;

  bool? _online;
  bool _checkingConnectivity = true;

  @override
  void initState() {
    super.initState();
    _refreshConnectivity();
    _loadLastResult();
    _network.connectivityStream.listen((_) => _refreshConnectivity());
  }

  Future<void> _loadLastResult() async {
    final history = await _history.load();
    if (history.isNotEmpty && mounted) {
      setState(() {
        _lastResult = history.first;
        _gaugeValue = history.first.downloadMbps;
        _gaugeMax = _autoMax(history.first.downloadMbps);
      });
    }
  }

  Future<void> _refreshConnectivity() async {
    setState(() => _checkingConnectivity = true);
    final ok = await _network.hasInternetAccess();
    if (!mounted) return;
    setState(() {
      _online = ok;
      _checkingConnectivity = false;
    });
  }

  double _autoMax(double value) {
    if (value <= 25) return 25;
    if (value <= 50) return 50;
    if (value <= 100) return 100;
    if (value <= 250) return 250;
    if (value <= 500) return 500;
    return 1000;
  }

  Future<void> _runTest() async {
    if (_isTesting) return;
    setState(() {
      _isTesting = true;
      _stage = SpeedTestStage.ping;
      _gaugeValue = 0;
    });

    final result = await _network.runSpeedTest(
      onProgress: (progress) {
        if (!mounted) return;
        setState(() {
          _stage = progress.stage;
          if (progress.stage == SpeedTestStage.download && progress.liveMbps != null) {
            _gaugeValue = progress.liveMbps!;
            _gaugeMax = _autoMax(_gaugeValue);
          }
        });
      },
    );

    await _history.add(result);
    if (!mounted) return;
    setState(() {
      _isTesting = false;
      _stage = SpeedTestStage.done;
      _lastResult = result;
      _gaugeValue = result.downloadMbps;
      _gaugeMax = _autoMax(result.downloadMbps);
    });
  }

  String _stageLabel() {
    switch (_stage) {
      case SpeedTestStage.idle:
        return 'Tap start to test your connection';
      case SpeedTestStage.ping:
        return 'Measuring ping & jitter…';
      case SpeedTestStage.download:
        return 'Testing download speed…';
      case SpeedTestStage.upload:
        return 'Testing upload speed…';
      case SpeedTestStage.done:
        return 'Test complete';
    }
  }

  @override
  void dispose() {
    _network.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final result = _lastResult;
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  ShaderMask(
                    shaderCallback: (rect) => AppColors.primaryGradient.createShader(rect),
                    child: const Text(
                      'QIC',
                      style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Quick Internet Checker',
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55),
                    ),
                  ),
                ],
              ),
              _checkingConnectivity
                  ? const StatusPill(label: 'Checking…', tone: PillTone.warning)
                  : StatusPill(
                      label: _online == true ? 'Online' : 'Offline',
                      tone: _online == true ? PillTone.online : PillTone.offline,
                    ),
            ],
          ),
          const SizedBox(height: 20),
          GlassCard(
            borderRadius: BorderRadius.circular(28),
            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
            child: Column(
              children: [
                SizedBox(
                  height: 220,
                  child: SpeedGauge(
                    value: _gaugeValue,
                    maxValue: _gaugeMax,
                    centerCaption: _stageLabel(),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: _isTesting ? null : AppColors.primaryGradient,
                      color: _isTesting ? Colors.grey.withValues(alpha: 0.3) : null,
                      boxShadow: _isTesting
                          ? null
                          : [BoxShadow(color: AppColors.cyan.withValues(alpha: 0.35), blurRadius: 20, offset: const Offset(0, 8))],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: _isTesting ? null : _runTest,
                        child: Center(
                          child: _isTesting
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                                )
                              : const Text(
                                  'START TEST',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.4,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 2.6,
            children: [
              MetricTile(
                icon: Icons.arrow_downward_rounded,
                label: 'Download',
                value: result == null ? '—' : '${result.downloadMbps.toStringAsFixed(1)} Mbps',
                accent: AppColors.cyan,
              ),
              MetricTile(
                icon: Icons.arrow_upward_rounded,
                label: 'Upload',
                value: result == null ? '—' : '${result.uploadMbps.toStringAsFixed(1)} Mbps',
                accent: AppColors.violet,
              ),
              MetricTile(
                icon: Icons.speed_rounded,
                label: 'Ping',
                value: result == null ? '—' : '${result.pingMs} ms',
                accent: AppColors.magenta,
              ),
              MetricTile(
                icon: Icons.graphic_eq_rounded,
                label: 'Jitter',
                value: result == null ? '—' : '${result.jitterMs} ms',
                accent: AppColors.warning,
              ),
              MetricTile(
                icon: Icons.wifi_tethering_error_rounded,
                label: 'Packet loss',
                value: result == null ? '—' : '${result.packetLossPercent.toStringAsFixed(0)}%',
                accent: AppColors.offline,
              ),
              MetricTile(
                icon: Icons.schedule_rounded,
                label: 'Last tested',
                value: result == null ? 'Never' : _timeAgo(result.timestamp),
                accent: AppColors.online,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _timeAgo(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
