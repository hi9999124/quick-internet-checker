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
  final String? asn;
  final String? postal;
  final String? timezone;
  final double? latitude;
  final double? longitude;
  final String? currency;
  final String? callingCode;
  final String? continentCode;

  const IpInfo({
    required this.ip,
    this.city,
    this.region,
    this.country,
    this.isp,
    this.asn,
    this.postal,
    this.timezone,
    this.latitude,
    this.longitude,
    this.currency,
    this.callingCode,
    this.continentCode,
  });

  String get location {
    final parts = [city, region, country].where((p) => p != null && p.isNotEmpty);
    return parts.isEmpty ? 'Unknown location' : parts.join(', ');
  }

  Map<String, dynamic> toJson() => {
        'ip': ip,
        'city': city,
        'region': region,
        'country': country,
        'isp': isp,
        'asn': asn,
        'postal': postal,
        'timezone': timezone,
        'latitude': latitude,
        'longitude': longitude,
        'currency': currency,
        'callingCode': callingCode,
        'continentCode': continentCode,
      };

  factory IpInfo.fromJson(Map<String, dynamic> json) => IpInfo(
        ip: json['ip'] as String,
        city: json['city'] as String?,
        region: json['region'] as String?,
        country: json['country'] as String?,
        isp: json['isp'] as String?,
        asn: json['asn'] as String?,
        postal: json['postal'] as String?,
        timezone: json['timezone'] as String?,
        latitude: (json['latitude'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
        currency: json['currency'] as String?,
        callingCode: json['callingCode'] as String?,
        continentCode: json['continentCode'] as String?,
      );
}
