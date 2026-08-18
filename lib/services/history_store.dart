import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/speed_sample.dart';

class HistoryStore {
  static const _key = 'qic_speed_history_v1';
  static const _maxEntries = 100;

  /// Bumped whenever history is added to or cleared, so screens kept alive
  /// by an IndexedStack (e.g. the History tab) know to reload instead of
  /// showing whatever they last loaded at startup.
  static final ValueNotifier<int> changes = ValueNotifier<int>(0);

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
    changes.value++;
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
    changes.value++;
  }
}
