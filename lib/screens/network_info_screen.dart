import 'package:flutter/material.dart';

import '../models/privacy_signals.dart';
import '../models/speed_sample.dart';
import '../services/network_service.dart';
import '../services/snapshot_cache.dart';
import '../theme/app_colors.dart';
import '../widgets/cache_badge.dart';
import '../widgets/glass_card.dart';
import '../widgets/info_section.dart';
import '../widgets/status_pill.dart';
import 'full_report_screen.dart';
import 'privacy_screen.dart';

class NetworkInfoScreen extends StatefulWidget {
  const NetworkInfoScreen({super.key});

  @override
  State<NetworkInfoScreen> createState() => _NetworkInfoScreenState();
}

class _NetworkInfoScreenState extends State<NetworkInfoScreen> {
  final NetworkService _network = NetworkService();
  final SnapshotCache _cache = SnapshotCache();

  IpInfo? _ipInfo;
  String? _ipError;
  bool _usingCache = false;
  DateTime? _cachedAt;
  List<PingResult> _pings = [];
  int? _dnsMs;
  bool _dnsSupported = true;
  bool _loading = true;
  LocalNetworkInfo? _localNetworkInfo;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() => _loading = true);

    final cached = await _cache.load();
    if (cached != null && mounted) {
      setState(() {
        _ipInfo = cached.ipInfo;
        _usingCache = true;
        _cachedAt = cached.timestamp;
      });
    }

    await Future.wait([
      _loadIpInfo(cached),
      _loadPings(),
      _loadDns(),
      _loadLocalNetwork(),
    ]);
    if (!mounted) return;
    setState(() => _loading = false);
  }

  Future<void> _loadIpInfo(CachedSnapshot? cached) async {
    try {
      final info = await _network.fetchIpInfo();
      if (!mounted) return;
      await _cache.save(CachedSnapshot(
        ipInfo: info,
        dnsMs: _dnsMs,
        latencyMs: cached?.latencyMs,
        timestamp: DateTime.now(),
      ));
      setState(() {
        _ipInfo = info;
        _usingCache = false;
        _cachedAt = DateTime.now();
      });
    } catch (_) {
      if (!mounted) return;
      if (cached == null) {
        setState(() => _ipError = 'Could not reach IP lookup service.');
      }
      // else: keep showing the cached value already set in state.
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

  Future<void> _loadLocalNetwork() async {
    final info = await _network.localNetworkInfo();
    if (!mounted) return;
    setState(() => _localNetworkInfo = info);
  }

  @override
  void dispose() {
    _network.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final privacy = analyzePrivacy(
      ispOrg: _ipInfo?.isp,
      ipv6Supported: _localNetworkInfo?.hasIPv6 ?? false,
      localIPv4: _localNetworkInfo?.localIPv4,
    );

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _loadAll,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Flexible(
                  child: Text('Network Info', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const FullReportScreen()),
                  ),
                  icon: const Icon(Icons.fact_check_rounded),
                  tooltip: 'Full report',
                ),
              ],
            ),
            const SizedBox(height: 8),
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Flexible(
                        child: Text('Public IP & ISP', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                      ),
                      const SizedBox(width: 8),
                      if (_usingCache && _cachedAt != null)
                        CacheBadge(since: _cachedAt!)
                      else if (_loading)
                        const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_ipInfo != null) ...[
                    InfoRow(label: 'IP address', value: _ipInfo!.ip),
                    InfoRow(label: 'ISP', value: _ipInfo!.isp ?? 'Unknown'),
                    InfoRow(label: 'ASN', value: _ipInfo!.asn ?? 'Unknown'),
                    InfoRow(label: 'City', value: _ipInfo!.city ?? 'Unknown'),
                    InfoRow(label: 'Region', value: _ipInfo!.region ?? 'Unknown'),
                    InfoRow(label: 'Country', value: _ipInfo!.country ?? 'Unknown'),
                    InfoRow(label: 'Postal code', value: _ipInfo!.postal ?? 'Unknown'),
                    InfoRow(label: 'Timezone', value: _ipInfo!.timezone ?? 'Unknown'),
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
                              Flexible(child: Text(p.label)),
                              const SizedBox(width: 8),
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
                    InfoRow(label: 'example.com lookup', value: _dnsMs == null ? 'Testing…' : '$_dnsMs ms'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            GlassCard(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => PrivacyScreen(signals: privacy, ip: _ipInfo)),
              ),
              child: Row(
                children: [
                  Icon(Icons.shield_outlined, color: AppColors.violet),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Privacy', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                        SizedBox(height: 2),
                        Text('VPN heuristic, IP exposure, DNS privacy notes'),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

