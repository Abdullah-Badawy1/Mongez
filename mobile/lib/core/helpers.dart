import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppPrefs {
  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // ── Theme ──────────────────────────────────────────
  static const String _themeKey = 'is_dark_mode';

  static bool getIsDarkMode(BuildContext context) {
    final savedTheme = _prefs?.getBool(_themeKey);

    if (savedTheme != null) {
      return savedTheme;
    }

    final brightness = MediaQuery.of(context).platformBrightness;
    return brightness == Brightness.dark;
  }

  static Future<void> setDarkMode(bool value) async {
    await _prefs?.setBool(_themeKey, value);
  }

  // ── Locale ─────────────────────────────────────────
  static const String _localeKey = 'locale';

  static String get locale {
    final savedLocale = _prefs?.getString(_localeKey);

    if (savedLocale != null) {
      return savedLocale;
    }

    final systemLang =
        WidgetsBinding.instance.platformDispatcher.locale.languageCode;

    if (['ar', 'en'].contains(systemLang)) {
      return systemLang;
    }

    return 'en';
  }

  static Future<void> setLocale(String langCode) async {
    await _prefs?.setString(_localeKey, langCode);
  }

  // ── Auth tokens ────────────────────────────────────
  static const _accessKey = 'access_token';
  static const _refreshKey = 'refresh_token';
  static const _roleKey = 'user_role';
  static const _usernameKey = 'username';

  static String? get accessToken => _prefs?.getString(_accessKey);
  static String? get refreshToken => _prefs?.getString(_refreshKey);
  static String? get userRole => _prefs?.getString(_roleKey);
  static String? get username => _prefs?.getString(_usernameKey);

  static Future<void> setAccessToken(String token) async =>
      _prefs?.setString(_accessKey, token);

  static Future<void> saveTokens({
    required String access,
    required String refresh,
    required String role,
    required String username,
  }) async {
    await _prefs?.setString(_accessKey, access);
    await _prefs?.setString(_refreshKey, refresh);
    await _prefs?.setString(_roleKey, role);
    await _prefs?.setString(_usernameKey, username);
  }

  static Future<void> clearTokens() async {
    await _prefs?.remove(_accessKey);
    await _prefs?.remove(_refreshKey);
    await _prefs?.remove(_roleKey);
    await _prefs?.remove(_usernameKey);
  }

  static bool get isLoggedIn => _prefs?.getString(_accessKey) != null;
}
