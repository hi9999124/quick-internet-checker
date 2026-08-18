/// Heuristic, client-side-only privacy signals. Nothing here is a
/// definitive detector (that would require a server-side vantage point) —
/// each field says plainly what it actually checked.
class PrivacySignals {
  final bool possibleVpnOrHosting;
  final String vpnReason;
  final bool ipv6Supported;
  final String? localIPv4;
  final bool encryptedTransport;

  const PrivacySignals({
    required this.possibleVpnOrHosting,
    required this.vpnReason,
    required this.ipv6Supported,
    required this.localIPv4,
    required this.encryptedTransport,
  });
}

const _hostingKeywords = [
  'vpn', 'hosting', 'cloud', 'datacenter', 'data center', 'server',
  'amazon', 'aws', 'google cloud', 'azure', 'digitalocean', 'linode',
  'ovh', 'hetzner', 'proxy',
];

PrivacySignals analyzePrivacy({
  required String? ispOrg,
  required bool ipv6Supported,
  required String? localIPv4,
}) {
  final org = (ispOrg ?? '').toLowerCase();
  final match = _hostingKeywords.where((k) => org.contains(k)).toList();
  return PrivacySignals(
    possibleVpnOrHosting: match.isNotEmpty,
    vpnReason: match.isEmpty
        ? 'ISP name doesn\'t match common hosting/VPN providers.'
        : 'ISP name contains "${match.first}" — often associated with hosting/VPN/proxy networks.',
    ipv6Supported: ipv6Supported,
    localIPv4: localIPv4,
    encryptedTransport: true,
  );
}
