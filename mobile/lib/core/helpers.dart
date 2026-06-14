import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppPrefs {
  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // ── Onboarding ─────────────────────────────────────
  static const String _onboardingKey = 'onboarding_seen';

  static bool get isOnboardingSeen => _prefs?.getBool(_onboardingKey) ?? false;

  static Future<void> setOnboardingSeen(bool value) async {
    await _prefs?.setBool(_onboardingKey, value);
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
}
