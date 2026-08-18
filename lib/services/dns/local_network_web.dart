class LocalNetworkInfo {
  final String? localIPv4;
  final bool hasIPv6;

  const LocalNetworkInfo({this.localIPv4, required this.hasIPv6});
}

// Browsers don't expose local network interfaces to scripts.
Future<LocalNetworkInfo> readLocalNetworkInfo() async => const LocalNetworkInfo(hasIPv6: false);
