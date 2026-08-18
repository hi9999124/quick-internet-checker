import 'dart:io';

class LocalNetworkInfo {
  final String? localIPv4;
  final bool hasIPv6;

  const LocalNetworkInfo({this.localIPv4, required this.hasIPv6});
}

Future<LocalNetworkInfo> readLocalNetworkInfo() async {
  try {
    final interfaces = await NetworkInterface.list(includeLoopback: false);
    String? v4;
    var hasV6 = false;
    for (final iface in interfaces) {
      for (final addr in iface.addresses) {
        if (addr.type == InternetAddressType.IPv4 && v4 == null) {
          v4 = addr.address;
        }
        if (addr.type == InternetAddressType.IPv6 && !addr.isLinkLocal) {
          hasV6 = true;
        }
      }
    }
    return LocalNetworkInfo(localIPv4: v4, hasIPv6: hasV6);
  } catch (_) {
    return const LocalNetworkInfo(hasIPv6: false);
  }
}
