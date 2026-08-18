import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;

import '../models/speed_sample.dart';
import 'dns/dns_lookup.dart';
import 'dns/local_network.dart';

export 'dns/local_network.dart' show LocalNetworkInfo;

enum SpeedTestStage { idle, ping, download, upload, done }

class SpeedTestProgress {
  final SpeedTestStage stage;
  final double fractionOfStage;
  final double? liveMbps;

  const SpeedTestProgress({
    required this.stage,
    this.fractionOfStage = 0,
    this.liveMbps,
  });
}

/// Well-known, CORS-friendly hosts used purely as latency probes.
const Map<String, String> pingTargets = {
  'Cloudflare': 'https://1.1.1.1/cdn-cgi/trace',
  'Google': 'https://www.google.com/generate_204',
  'Amazon': 'https://aws.amazon.com/favicon.ico',
  'Microsoft': 'https://www.microsoft.com/favicon.ico',
};

const String _speedHost = 'https://speed.cloudflare.com';

class NetworkService {
  final http.Client _client = http.Client();

  Stream<List<ConnectivityResult>> get connectivityStream =>
      Connectivity().onConnectivityChanged;

  Future<List<ConnectivityResult>> currentConnectivity() =>
      Connectivity().checkConnectivity();

  /// A real reachability check — connectivity_plus only reports link state,
  /// not whether the link actually reaches the internet.
  Future<bool> hasInternetAccess({Duration timeout = const Duration(seconds: 5)}) async {
    try {
      final res = await _client
          .head(Uri.parse('https://www.google.com/generate_204'))
          .timeout(timeout);
      return res.statusCode >= 200 && res.statusCode < 400;
    } catch (_) {
      try {
        final res = await _client
            .head(Uri.parse('https://1.1.1.1/cdn-cgi/trace'))
            .timeout(timeout);
        return res.statusCode >= 200 && res.statusCode < 400;
      } catch (_) {
        return false;
      }
    }
  }

  Future<IpInfo> fetchIpInfo() async {
    final res = await _client
        .get(Uri.parse('https://ipapi.co/json/'))
        .timeout(const Duration(seconds: 8));
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return IpInfo(
      ip: (data['ip'] ?? 'Unknown').toString(),
      city: data['city']?.toString(),
      region: data['region']?.toString(),
      country: data['country_name']?.toString(),
      isp: data['org']?.toString(),
      asn: data['asn']?.toString(),
      postal: data['postal']?.toString(),
      timezone: data['timezone']?.toString(),
      latitude: (data['latitude'] as num?)?.toDouble(),
      longitude: (data['longitude'] as num?)?.toDouble(),
      currency: data['currency']?.toString(),
      callingCode: data['country_calling_code']?.toString(),
      continentCode: data['continent_code']?.toString(),
    );
  }

  Future<List<PingResult>> pingAll({Duration timeout = const Duration(seconds: 5)}) async {
    final results = <PingResult>[];
    for (final entry in pingTargets.entries) {
      final ms = await _pingOnce(entry.value, timeout: timeout);
      results.add(PingResult(label: entry.key, host: entry.value, ms: ms));
    }
    return results;
  }

  Future<int?> _pingOnce(String url, {Duration timeout = const Duration(seconds: 5)}) async {
    final sw = Stopwatch()..start();
    try {
      await _client.head(Uri.parse(url)).timeout(timeout);
      sw.stop();
      return sw.elapsedMilliseconds;
    } catch (_) {
      return null;
    }
  }

  Future<int?> dnsLookupMs(String host) => measureDnsLookupMs(host);

  Future<LocalNetworkInfo> localNetworkInfo() => readLocalNetworkInfo();

  /// Runs ping/jitter, download, then upload legs and reports live progress.
  Future<SpeedSample> runSpeedTest({
    void Function(SpeedTestProgress progress)? onProgress,
  }) async {
    onProgress?.call(const SpeedTestProgress(stage: SpeedTestStage.ping));
    final latencies = <int>[];
    var failures = 0;
    const pingAttempts = 6;
    for (var i = 0; i < pingAttempts; i++) {
      final ms = await _pingOnce('$_speedHost/__down?bytes=0');
      if (ms != null) {
        latencies.add(ms);
      } else {
        failures++;
      }
      onProgress?.call(SpeedTestProgress(
        stage: SpeedTestStage.ping,
        fractionOfStage: (i + 1) / pingAttempts,
      ));
    }
    final pingMs = latencies.isEmpty
        ? 0
        : (latencies.reduce((a, b) => a + b) / latencies.length).round();
    final jitterMs = _jitter(latencies);
    final packetLoss = (failures / pingAttempts) * 100;

    onProgress?.call(const SpeedTestProgress(stage: SpeedTestStage.download));
    final downloadMbps = await _measureDownload(onProgress: onProgress);

    onProgress?.call(const SpeedTestProgress(stage: SpeedTestStage.upload));
    final uploadMbps = await _measureUpload(onProgress: onProgress);

    onProgress?.call(const SpeedTestProgress(stage: SpeedTestStage.done, fractionOfStage: 1));

    return SpeedSample(
      downloadMbps: downloadMbps,
      uploadMbps: uploadMbps,
      pingMs: pingMs,
      jitterMs: jitterMs,
      packetLossPercent: packetLoss,
      timestamp: DateTime.now(),
    );
  }

  int _jitter(List<int> samples) {
    if (samples.length < 2) return 0;
    var total = 0;
    for (var i = 1; i < samples.length; i++) {
      total += (samples[i] - samples[i - 1]).abs();
    }
    return (total / (samples.length - 1)).round();
  }

  Future<double> _measureDownload({
    void Function(SpeedTestProgress progress)? onProgress,
    int bytes = 30 * 1000 * 1000,
  }) async {
    final uri = Uri.parse('$_speedHost/__down?bytes=$bytes');
    final request = http.Request('GET', uri);
    final sw = Stopwatch()..start();
    try {
      final streamed = await _client.send(request).timeout(const Duration(seconds: 20));
      var received = 0;
      await for (final chunk in streamed.stream) {
        received += chunk.length;
        final elapsedSec = sw.elapsedMilliseconds / 1000.0;
        if (elapsedSec > 0.15) {
          final mbps = (received * 8 / 1000000) / elapsedSec;
          onProgress?.call(SpeedTestProgress(
            stage: SpeedTestStage.download,
            fractionOfStage: min(received / bytes, 1.0),
            liveMbps: mbps,
          ));
        }
      }
      sw.stop();
      final elapsedSec = sw.elapsedMilliseconds / 1000.0;
      if (elapsedSec <= 0) return 0;
      return (received * 8 / 1000000) / elapsedSec;
    } catch (_) {
      return 0;
    }
  }

  Future<double> _measureUpload({
    void Function(SpeedTestProgress progress)? onProgress,
    int bytes = 8 * 1000 * 1000,
  }) async {
    final payload = _randomBytes(bytes);
    final uri = Uri.parse('$_speedHost/__up');
    final sw = Stopwatch()..start();
    try {
      onProgress?.call(const SpeedTestProgress(stage: SpeedTestStage.upload, fractionOfStage: 0.1));
      await _client
          .post(uri, body: payload, headers: {'Content-Type': 'application/octet-stream'})
          .timeout(const Duration(seconds: 25));
      sw.stop();
      final elapsedSec = sw.elapsedMilliseconds / 1000.0;
      onProgress?.call(const SpeedTestProgress(stage: SpeedTestStage.upload, fractionOfStage: 1));
      if (elapsedSec <= 0) return 0;
      return (bytes * 8 / 1000000) / elapsedSec;
    } catch (_) {
      return 0;
    }
  }

  Uint8List _randomBytes(int length) {
    final rand = Random();
    final bytes = Uint8List(length);
    for (var i = 0; i < length; i++) {
      bytes[i] = rand.nextInt(256);
    }
    return bytes;
  }

  void dispose() => _client.close();
}
