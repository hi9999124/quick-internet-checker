import 'package:flutter/material.dart';

import '../models/device_snapshot.dart';
import '../models/history_stats.dart';
import '../models/privacy_signals.dart';
import '../models/speed_sample.dart';
import '../services/device_info_service.dart';
import '../services/history_store.dart';
import '../services/network_service.dart';
import '../services/snapshot_cache.dart';
import '../theme/app_colors.dart';
import '../widgets/cache_badge.dart';
import '../widgets/info_section.dart';
import '../widgets/page_header.dart';
import '../widgets/status_pill.dart';
import 'device_info_screen.dart';
import 'privacy_screen.dart';
import 'stats_screen.dart';

/// The comprehensive "everything QIC knows right now" report: connection,
/// latency, IP/geo, privacy, device, and history stats in one scroll.
class FullReportScreen extends StatefulWidget {
  const FullReportScreen({super.key});

  @override
  State<FullReportScreen> createState() => _FullReportScreenState();
}

class _FullReportScreenState extends State<FullReportScreen> {
  final NetworkService _network = NetworkService();
  final HistoryStore _history = HistoryStore();
  final SnapshotCache _cache = SnapshotCache();
  final DeviceInfoService _deviceInfoService = DeviceInfoService();

  bool _loading = true;
  bool? _online;
  IpInfo? _ipInfo;
  bool _usingCache = false;
  DateTime? _cachedAt;
  int? _dnsMs;
  bool _dnsSupported = true;
  List<PingResult> _pings = [];
  LocalNetworkInfo? _localNetworkInfo;
  DeviceSnapshot? _device;
  HistoryStats _stats = HistoryStats.fromSamples(const []);
  SpeedSample? _lastResult;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);

    final cached = await _cache.load();
    if (cached != null && mounted) {
      setState(() {
        _ipInfo = cached.ipInfo;
        _dnsMs = cached.dnsMs;
        _usingCache = true;
        _cachedAt = cached.timestamp;
      });
    }

    final history = await _history.load();
    final device = await _deviceInfoService.load();
    if (!mounted) return;
    setState(() {
      _stats = HistoryStats.fromSamples(history);
      _lastResult = history.isEmpty ? null : history.first;
      _device = device;
    });

    final online = await _network.hasInternetAccess();
    final localNet = await _network.localNetworkInfo();
    if (!mounted) return;
    setState(() {
      _online = online;
      _localNetworkInfo = localNet;
    });

    final results = await Future.wait([
      _network.fetchIpInfo().then<IpInfo?>((v) => v).catchError((_) => null),
      _network.dnsLookupMs('example.com'),
      _network.pingAll(),
    ]);
    if (!mounted) return;
    final ipInfo = results[0] as IpInfo?;
    final dnsMs = results[1] as int?;
    final pings = results[2] as List<PingResult>;

    if (ipInfo != null) {
      final bestPing = pings.where((p) => p.isReachable).map((p) => p.ms!);
      await _cache.save(CachedSnapshot(
        ipInfo: ipInfo,
        dnsMs: dnsMs,
        latencyMs: bestPing.isEmpty ? null : bestPing.reduce((a, b) => a < b ? a : b),
        timestamp: DateTime.now(),
      ));
      setState(() {
        _ipInfo = ipInfo;
        _usingCache = false;
        _cachedAt = DateTime.now();
      });
    }
    setState(() {
      _dnsMs = dnsMs ?? _dnsMs;
      _dnsSupported = dnsMs != null || cached != null;
      _pings = pings;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _network.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ip = _ipInfo;
    final device = _device;
    final localNet = _localNetworkInfo;
    final privacy = analyzePrivacy(
      ispOrg: ip?.isp,
      ipv6Supported: localNet?.hasIPv6 ?? false,
      localIPv4: localNet?.localIPv4,
    );

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
          children: [
            PageHeader(
              title: 'Full network report',
              trailing: _loading
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : null,
            ),
            const SizedBox(height: 12),

            InfoSectionCard(
              title: 'Connection',
              icon: Icons.wifi_rounded,
              accent: AppColors.cyan,
              trailing: _online == null
                  ? null
                  : StatusPill(
                      label: _online == true ? 'Online' : 'Offline',
                      tone: _online == true ? PillTone.online : PillTone.offline,
                    ),
              children: [
                InfoRow(label: 'Status', value: _online == null ? 'Checking…' : (_online! ? 'Online' : 'Offline')),
                InfoRow(
                  label: 'Download (last test)',
                  value: _lastResult == null ? '—' : '${_lastResult!.downloadMbps.toStringAsFixed(1)} Mbps',
                ),
                InfoRow(
                  label: 'Upload (last test)',
                  value: _lastResult == null ? '—' : '${_lastResult!.uploadMbps.toStringAsFixed(1)} Mbps',
                ),
                InfoRow(label: 'Ping', value: _lastResult == null ? '—' : '${_lastResult!.pingMs} ms'),
                InfoRow(label: 'Jitter', value: _lastResult == null ? '—' : '${_lastResult!.jitterMs} ms'),
                InfoRow(
                  label: 'Packet loss',
                  value: _lastResult == null ? '—' : '${_lastResult!.packetLossPercent.toStringAsFixed(0)}%',
                ),
                InfoRow(
                  label: 'DNS lookup time',
                  value: !_dnsSupported ? 'N/A on web' : (_dnsMs == null ? '—' : '$_dnsMs ms'),
                ),
              ],
            ),
            const SizedBox(height: 14),

            InfoSectionCard(
              title: 'Latency to major networks',
              icon: Icons.podcasts_rounded,
              accent: AppColors.magenta,
              children: _pings.isEmpty
                  ? [const Text('Pinging…')]
                  : _pings
                      .map((p) => InfoRow(
                            label: p.label,
                            value: p.isReachable ? '${p.ms} ms' : 'unreachable',
                            valueColor: p.isReachable ? null : AppColors.offline,
                          ))
                      .toList(),
            ),
            const SizedBox(height: 14),

            InfoSectionCard(
              title: 'IP & location',
              icon: Icons.public_rounded,
              accent: AppColors.online,
              trailing: (_usingCache && _cachedAt != null) ? CacheBadge(since: _cachedAt!) : null,
              children: ip == null
                  ? [const Text('Looking up your IP…')]
                  : [
                      InfoRow(label: 'IP address', value: ip.ip),
                      InfoRow(label: 'ISP / organization', value: ip.isp ?? 'Unknown'),
                      InfoRow(label: 'ASN', value: ip.asn ?? 'Unknown'),
                      InfoRow(label: 'City', value: ip.city ?? 'Unknown'),
                      InfoRow(label: 'Region', value: ip.region ?? 'Unknown'),
                      InfoRow(label: 'Country', value: ip.country ?? 'Unknown'),
                      InfoRow(label: 'Postal code', value: ip.postal ?? 'Unknown'),
                      InfoRow(label: 'Continent', value: ip.continentCode ?? 'Unknown'),
                      InfoRow(label: 'Timezone', value: ip.timezone ?? 'Unknown'),
                      InfoRow(
                        label: 'Coordinates',
                        value: (ip.latitude == null || ip.longitude == null)
                            ? 'Unknown'
                            : '${ip.latitude!.toStringAsFixed(3)}, ${ip.longitude!.toStringAsFixed(3)}',
                      ),
                      InfoRow(label: 'Currency', value: ip.currency ?? 'Unknown'),
                      InfoRow(label: 'Calling code', value: ip.callingCode ?? 'Unknown'),
                    ],
            ),
            const SizedBox(height: 14),

            InfoSectionCard(
              title: 'Privacy signals',
              icon: Icons.shield_outlined,
              accent: AppColors.violet,
              trailing: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => PrivacyScreen(signals: privacy, ip: ip)),
                ),
                child: const Text('Details'),
              ),
              children: [
                InfoRow(
                  label: 'Possible VPN/hosting IP',
                  value: privacy.possibleVpnOrHosting ? 'Possibly' : 'No signal',
                  valueColor: privacy.possibleVpnOrHosting ? AppColors.warning : AppColors.online,
                ),
                InfoRow(label: 'IPv6 support', value: privacy.ipv6Supported ? 'Yes' : 'No / unknown'),
                InfoRow(label: 'Local IP address', value: privacy.localIPv4 ?? 'Not available on web'),
                InfoRow(label: 'App transport', value: 'HTTPS-only'),
              ],
            ),
            const SizedBox(height: 14),

            InfoSectionCard(
              title: 'Device & app',
              icon: Icons.smartphone_rounded,
              accent: AppColors.cyanBright,
              trailing: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => DeviceInfoScreen(device: device)),
                ),
                child: const Text('Details'),
              ),
              children: [
                InfoRow(label: 'Platform', value: device?.platform ?? 'Loading…'),
                InfoRow(label: 'OS version', value: device?.osVersion ?? 'Loading…'),
                InfoRow(label: 'App version', value: device == null ? 'Loading…' : '${device.appVersion} (${device.buildNumber})'),
              ],
            ),
            const SizedBox(height: 14),

            InfoSectionCard(
              title: 'History & stats',
              icon: Icons.bar_chart_rounded,
              accent: AppColors.warning,
              trailing: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const StatsScreen()),
                ),
                child: const Text('Details'),
              ),
              children: [
                InfoRow(label: 'Total tests run', value: '${_stats.totalTests}'),
                InfoRow(label: 'Tests today', value: '${_stats.testsToday}'),
                InfoRow(
                  label: 'Average download',
                  value: _stats.totalTests == 0 ? '—' : '${_stats.avgDownloadMbps.toStringAsFixed(1)} Mbps',
                ),
                InfoRow(
                  label: 'Best download',
                  value: _stats.totalTests == 0 ? '—' : '${_stats.bestDownloadMbps.toStringAsFixed(1)} Mbps',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
