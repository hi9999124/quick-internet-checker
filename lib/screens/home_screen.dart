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

  IpInfo? _ipInfo;
  bool _ipFailed = false;
  int? _dnsMs;
  bool _dnsSupported = true;
  int? _latencyMs;
  bool _snapshotLoading = true;

  @override
  void initState() {
    super.initState();
    _refreshConnectivity();
    _loadLastResult();
    _loadSnapshot();
    _network.connectivityStream.listen((_) => _refreshConnectivity());
  }

  Future<void> _loadSnapshot() async {
    setState(() => _snapshotLoading = true);
    final results = await Future.wait([
      _network.fetchIpInfo().then<IpInfo?>((v) => v).catchError((_) => null),
      _network.dnsLookupMs('example.com'),
      _network.pingAll(),
    ]);
    if (!mounted) return;
    final ipInfo = results[0] as IpInfo?;
    final dnsMs = results[1] as int?;
    final pings = (results[2] as List<PingResult>).where((p) => p.isReachable).map((p) => p.ms!);
    setState(() {
      _ipInfo = ipInfo;
      _ipFailed = ipInfo == null;
      _dnsMs = dnsMs;
      _dnsSupported = dnsMs != null;
      _latencyMs = pings.isEmpty ? null : pings.reduce((a, b) => a < b ? a : b);
      _snapshotLoading = false;
    });
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
          const SizedBox(height: 16),
          _NetworkSnapshotCard(
            loading: _snapshotLoading,
            ip: _ipInfo?.ip,
            ipFailed: _ipFailed,
            isp: _ipInfo?.isp,
            location: _ipInfo?.location,
            dnsMs: _dnsMs,
            dnsSupported: _dnsSupported,
            latencyMs: _latencyMs,
            onRefresh: _loadSnapshot,
          ),
          const SizedBox(height: 16),
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

/// At-a-glance IP / DNS / latency readout, separate from the on-demand
/// download+upload speed test above.
class _NetworkSnapshotCard extends StatelessWidget {
  final bool loading;
  final String? ip;
  final bool ipFailed;
  final String? isp;
  final String? location;
  final int? dnsMs;
  final bool dnsSupported;
  final int? latencyMs;
  final VoidCallback onRefresh;

  const _NetworkSnapshotCard({
    required this.loading,
    required this.ip,
    required this.ipFailed,
    required this.isp,
    required this.location,
    required this.dnsMs,
    required this.dnsSupported,
    required this.latencyMs,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final mutedColor = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55);
    return GlassCard(
      borderRadius: BorderRadius.circular(20),
      padding: const EdgeInsets.fromLTRB(18, 14, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Network snapshot', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: mutedColor)),
              SizedBox(
                width: 30,
                height: 30,
                child: loading
                    ? const Padding(
                        padding: EdgeInsets.all(6),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : IconButton(
                        padding: EdgeInsets.zero,
                        iconSize: 18,
                        onPressed: onRefresh,
                        icon: const Icon(Icons.refresh_rounded),
                      ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 20,
            runSpacing: 10,
            children: [
              _SnapshotFact(
                icon: Icons.public_rounded,
                accent: AppColors.cyan,
                label: 'IP address',
                value: ipFailed ? 'Unavailable' : (ip ?? '—'),
              ),
              _SnapshotFact(
                icon: Icons.dns_rounded,
                accent: AppColors.violet,
                label: 'DNS lookup',
                value: !dnsSupported ? 'N/A on web' : (dnsMs == null ? '—' : '$dnsMs ms'),
              ),
              _SnapshotFact(
                icon: Icons.podcasts_rounded,
                accent: AppColors.magenta,
                label: 'Latency',
                value: latencyMs == null ? '—' : '$latencyMs ms',
              ),
              _SnapshotFact(
                icon: Icons.location_on_rounded,
                accent: AppColors.online,
                label: 'Location',
                value: location ?? '—',
              ),
            ],
          ),
          if (isp != null) ...[
            const SizedBox(height: 10),
            Text('ISP: $isp', style: TextStyle(fontSize: 12, color: mutedColor)),
          ],
        ],
      ),
    );
  }
}

class _SnapshotFact extends StatelessWidget {
  final IconData icon;
  final Color accent;
  final String label;
  final String value;

  const _SnapshotFact({required this.icon, required this.accent, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 150,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: accent),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5))),
                Text(
                  value,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
