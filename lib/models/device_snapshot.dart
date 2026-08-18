class DeviceSnapshot {
  final String platform;
  final String osVersion;
  final String deviceModel;
  final String appName;
  final String appVersion;
  final String buildNumber;
  final String locale;

  const DeviceSnapshot({
    required this.platform,
    required this.osVersion,
    required this.deviceModel,
    required this.appName,
    required this.appVersion,
    required this.buildNumber,
    required this.locale,
  });
}
