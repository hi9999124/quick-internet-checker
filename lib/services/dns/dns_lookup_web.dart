// Raw DNS lookups aren't exposed to browsers, so on web we report timing
// as unavailable rather than faking a number.
Future<int?> measureDnsLookupMs(String host) async => null;
