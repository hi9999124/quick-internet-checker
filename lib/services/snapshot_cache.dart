import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/speed_sample.dart';

/// Last-known network snapshot (IP/DNS/latency), persisted so the app has
/// something meaningful to show the moment it opens offline — before any
/// network call has had a chance to succeed or fail.
class CachedSnapshot {
  final IpInfo ipInfo;
  final int? dnsMs;
  final int? latencyMs;
  final DateTime timestamp;

  const CachedSnapshot({
    required this.ipInfo,
    required this.dnsMs,
    required this.latencyMs,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'ipInfo': ipInfo.toJson(),
        'dnsMs': dnsMs,
        'latencyMs': latencyMs,
        'timestamp': timestamp.toIso8601String(),
      };

  factory CachedSnapshot.fromJson(Map<String, dynamic> json) => CachedSnapshot(
        ipInfo: IpInfo.fromJson(json['ipInfo'] as Map<String, dynamic>),
        dnsMs: json['dnsMs'] as int?,
        latencyMs: json['latencyMs'] as int?,
        timestamp: DateTime.parse(json['timestamp'] as String),
      );
}

class SnapshotCache {
  static const _key = 'qic_last_snapshot_v1';

  Future<CachedSnapshot?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return null;
    try {
      return CachedSnapshot.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> save(CachedSnapshot snapshot) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(snapshot.toJson()));
  }
}
