import 'dart:io';

Future<int?> measureDnsLookupMs(String host) async {
  final sw = Stopwatch()..start();
  try {
    await InternetAddress.lookup(host);
    sw.stop();
    return sw.elapsedMilliseconds;
  } catch (_) {
    return null;
  }
}
