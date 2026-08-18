import 'speed_sample.dart';

class HistoryStats {
  final int totalTests;
  final int testsToday;
  final double avgDownloadMbps;
  final double avgUploadMbps;
  final double avgPingMs;
  final double bestDownloadMbps;
  final int bestPingMs;
  final DateTime? firstTestAt;

  const HistoryStats({
    required this.totalTests,
    required this.testsToday,
    required this.avgDownloadMbps,
    required this.avgUploadMbps,
    required this.avgPingMs,
    required this.bestDownloadMbps,
    required this.bestPingMs,
    required this.firstTestAt,
  });

  factory HistoryStats.fromSamples(List<SpeedSample> samples) {
    if (samples.isEmpty) {
      return const HistoryStats(
        totalTests: 0,
        testsToday: 0,
        avgDownloadMbps: 0,
        avgUploadMbps: 0,
        avgPingMs: 0,
        bestDownloadMbps: 0,
        bestPingMs: 0,
        firstTestAt: null,
      );
    }
    final now = DateTime.now();
    final today = samples.where((s) =>
        s.timestamp.year == now.year && s.timestamp.month == now.month && s.timestamp.day == now.day);
    final oldest = samples.reduce((a, b) => a.timestamp.isBefore(b.timestamp) ? a : b);

    return HistoryStats(
      totalTests: samples.length,
      testsToday: today.length,
      avgDownloadMbps: samples.map((s) => s.downloadMbps).reduce((a, b) => a + b) / samples.length,
      avgUploadMbps: samples.map((s) => s.uploadMbps).reduce((a, b) => a + b) / samples.length,
      avgPingMs: samples.map((s) => s.pingMs).reduce((a, b) => a + b) / samples.length,
      bestDownloadMbps: samples.map((s) => s.downloadMbps).reduce((a, b) => a > b ? a : b),
      bestPingMs: samples.map((s) => s.pingMs).reduce((a, b) => a < b ? a : b),
      firstTestAt: oldest.timestamp,
    );
  }
}
