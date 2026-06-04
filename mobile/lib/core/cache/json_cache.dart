import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// A tiny TTL cache backed by SharedPreferences.
///
/// Designed for the obvious offline cases: read the last list of workers /
/// orders / categories when the device is offline so the UI never lands on a
/// blank screen. We never use this cache for write paths.
///
/// Keys are namespaced with the prefix `cache_v1.`. Bumping the prefix is the
/// recommended way to invalidate everything when the schema changes.
class JsonCache {
  JsonCache._();

  static const _prefix = 'cache_v1.';
  static SharedPreferences? _prefs;

  static Future<void> _ensure() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// Save `value` under `key`. Stamped with `now` so [readFresh] can expire it.
  static Future<void> write(String key, Object? value) async {
    await _ensure();
    final payload = jsonEncode({
      'at': DateTime.now().toUtc().toIso8601String(),
      'value': value,
    });
    await _prefs!.setString('$_prefix$key', payload);
  }

  /// Read whatever is at `key`, ignoring age.
  static Future<dynamic> read(String key) async {
    await _ensure();
    final raw = _prefs!.getString('$_prefix$key');
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return decoded['value'];
    } catch (_) {
      return null;
    }
  }

  /// Read only if the entry is younger than `maxAge`. Returns `null` otherwise.
  static Future<dynamic> readFresh(String key, Duration maxAge) async {
    await _ensure();
    final raw = _prefs!.getString('$_prefix$key');
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final at = DateTime.parse(decoded['at'] as String);
      if (DateTime.now().toUtc().difference(at) > maxAge) return null;
      return decoded['value'];
    } catch (_) {
      return null;
    }
  }

  static Future<DateTime?> writtenAt(String key) async {
    await _ensure();
    final raw = _prefs!.getString('$_prefix$key');
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return DateTime.parse(decoded['at'] as String);
    } catch (_) {
      return null;
    }
  }

  static Future<void> remove(String key) async {
    await _ensure();
    await _prefs!.remove('$_prefix$key');
  }

  /// Wipe every entry created by this cache. Call on logout.
  static Future<void> clearAll() async {
    await _ensure();
    final keys =
        _prefs!.getKeys().where((k) => k.startsWith(_prefix)).toList();
    for (final k in keys) {
      await _prefs!.remove(k);
    }
  }
}
