import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter/widgets.dart';

import '../models/device_snapshot.dart';

class DeviceInfoService {
  Future<DeviceSnapshot> load() async {
    final plugin = DeviceInfoPlugin();
    final locale = WidgetsBinding.instance.platformDispatcher.locale.toString();

    String appName = 'QIC';
    String appVersion = 'Unknown';
    String buildNumber = 'Unknown';
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      appName = packageInfo.appName;
      appVersion = packageInfo.version;
      buildNumber = packageInfo.buildNumber;
    } catch (_) {
      // Package metadata is best-effort; keep the fallbacks.
    }

    String platform = 'Unknown';
    String osVersion = 'Unknown';
    String model = 'Unknown';

    try {
      if (kIsWeb) {
        final info = await plugin.webBrowserInfo;
        platform = 'Web (${info.browserName.name})';
        osVersion = info.platform ?? 'Unknown';
        model = info.userAgent ?? 'Unknown browser';
      } else if (defaultTargetPlatform == TargetPlatform.android) {
        final info = await plugin.androidInfo;
        platform = 'Android';
        osVersion = 'Android ${info.version.release} (SDK ${info.version.sdkInt})';
        model = '${info.manufacturer} ${info.model}';
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        final info = await plugin.iosInfo;
        platform = 'iOS';
        osVersion = '${info.systemName} ${info.systemVersion}';
        model = info.utsname.machine;
      } else if (defaultTargetPlatform == TargetPlatform.macOS) {
        final info = await plugin.macOsInfo;
        platform = 'macOS';
        osVersion = info.osRelease;
        model = info.model;
      } else if (defaultTargetPlatform == TargetPlatform.windows) {
        final info = await plugin.windowsInfo;
        platform = 'Windows';
        osVersion = info.displayVersion;
        model = info.productName;
      } else if (defaultTargetPlatform == TargetPlatform.linux) {
        final info = await plugin.linuxInfo;
        platform = 'Linux';
        osVersion = info.versionId ?? info.version ?? 'Unknown';
        model = info.prettyName;
      }
    } catch (_) {
      // Keep the 'Unknown' fallbacks — device info is best-effort.
    }

    return DeviceSnapshot(
      platform: platform,
      osVersion: osVersion,
      deviceModel: model,
      appName: appName,
      appVersion: appVersion,
      buildNumber: buildNumber,
      locale: locale,
    );
  }
}
