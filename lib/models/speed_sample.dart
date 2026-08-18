class SpeedSample {
  final double downloadMbps;
  final double uploadMbps;
  final int pingMs;
  final int jitterMs;
  final double packetLossPercent;
  final DateTime timestamp;

  const SpeedSample({
    required this.downloadMbps,
    required this.uploadMbps,
    required this.pingMs,
    required this.jitterMs,
    required this.packetLossPercent,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'downloadMbps': downloadMbps,
        'uploadMbps': uploadMbps,
        'pingMs': pingMs,
        'jitterMs': jitterMs,
        'packetLossPercent': packetLossPercent,
        'timestamp': timestamp.toIso8601String(),
      };

  factory SpeedSample.fromJson(Map<String, dynamic> json) => SpeedSample(
        downloadMbps: (json['downloadMbps'] as num).toDouble(),
        uploadMbps: (json['uploadMbps'] as num).toDouble(),
        pingMs: json['pingMs'] as int,
        jitterMs: json['jitterMs'] as int,
        packetLossPercent: (json['packetLossPercent'] as num).toDouble(),
        timestamp: DateTime.parse(json['timestamp'] as String),
      );
}

class PingResult {
  final String label;
  final String host;
  final int? ms;

  const PingResult({required this.label, required this.host, this.ms});

  bool get isReachable => ms != null;
}

class IpInfo {
  final String ip;
  final String? city;
  final String? region;
  final String? country;
  final String? isp;

  const IpInfo({
    required this.ip,
    this.city,
    this.region,
    this.country,
    this.isp,
  });

  String get location {
    final parts = [city, region, country].where((p) => p != null && p.isNotEmpty);
    return parts.isEmpty ? 'Unknown location' : parts.join(', ');
  }
}
