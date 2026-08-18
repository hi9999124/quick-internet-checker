import 'package:flutter/material.dart';

import '../models/speed_sample.dart';
import '../services/network_service.dart';
import '../theme/app_colors.dart';
import '../widgets/glass_card.dart';
import '../widgets/status_pill.dart';

class NetworkInfoScreen extends StatefulWidget {
  const NetworkInfoScreen({super.key});

  @override
  State<NetworkInfoScreen> createState() => _NetworkInfoScreenState();
}

class _NetworkInfoScreenState extends State<NetworkInfoScreen> {
  final NetworkService _network = NetworkService();

  IpInfo? _ipInfo;
  String? _ipError;
  List<PingResult> _pings = [];
  int? _dnsMs;
  bool _dnsSupported = true;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() => _loading = true);
    await Future.wait([
      _loadIpInfo(),
      _loadPings(),
      _loadDns(),
    ]);
    if (!mounted) return;
    setState(() => _loading = false);
  }

  Future<void> _loadIpInfo() async {
    try {
      final info = await _network.fetchIpInfo();
      if (!mounted) return;
      setState(() => _ipInfo = info);
    } catch (_) {
      if (!mounted) return;
      setState(() => _ipError = 'Could not reach IP lookup service.');
    }
  }

  Future<void> _loadPings() async {
    final results = await _network.pingAll();
    if (!mounted) return;
    setState(() => _pings = results);
  }

  Future<void> _loadDns() async {
    final ms = await _network.dnsLookupMs('example.com');
    if (!mounted) return;
    setState(() {
      _dnsMs = ms;
      _dnsSupported = ms != null;
    });
  }

  @override
  void dispose() {
    _network.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _loadAll,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
          children: [
            const Text('Network Info', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Public IP & ISP', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                      if (_loading) const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_ipInfo != null) ...[
                    _InfoRow(label: 'IP address', value: _ipInfo!.ip),
                    _InfoRow(label: 'ISP', value: _ipInfo!.isp ?? 'Unknown'),
                    _InfoRow(label: 'City', value: _ipInfo!.city ?? 'Unknown'),
                    _InfoRow(label: 'Region', value: _ipInfo!.region ?? 'Unknown'),
                    _InfoRow(label: 'Country', value: _ipInfo!.country ?? 'Unknown'),
                  ] else if (_ipError != null)
                    Text(_ipError!, style: TextStyle(color: AppColors.offline))
                  else
                    const Text('Looking up your IP…'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Latency to major networks', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                  const SizedBox(height: 12),
                  if (_pings.isEmpty)
                    const Text('Pinging…')
                  else
                    ..._pings.map((p) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(p.label),
                              StatusPill(
                                label: p.isReachable ? '${p.ms} ms' : 'unreachable',
                                tone: !p.isReachable
                                    ? PillTone.offline
                                    : (p.ms! < 80 ? PillTone.online : PillTone.warning),
                              ),
                            ],
                          ),
                        )),
                ],
              ),
            ),
            const SizedBox(height: 16),
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('DNS resolution', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                  const SizedBox(height: 12),
                  if (!_dnsSupported)
                    const Text('DNS timing isn\'t available on this platform (browser sandbox).')
                  else
                    _InfoRow(label: 'example.com lookup', value: _dnsMs == null ? 'Testing…' : '$_dnsMs ms'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6))),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
