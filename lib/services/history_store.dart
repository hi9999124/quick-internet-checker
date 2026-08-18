import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/speed_sample.dart';

class HistoryStore {
  static const _key = 'qic_speed_history_v1';
  static const _maxEntries = 100;

  Future<List<SpeedSample>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    return raw
        .map((e) => SpeedSample.fromJson(jsonDecode(e) as Map<String, dynamic>))
        .toList()
        .reversed
        .toList();
  }

  Future<void> add(SpeedSample sample) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    raw.add(jsonEncode(sample.toJson()));
    final trimmed = raw.length > _maxEntries
        ? raw.sublist(raw.length - _maxEntries)
        : raw;
    await prefs.setStringList(_key, trimmed);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
