import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider extends ChangeNotifier {
  static const String LANGUAGE_CODE = 'languageCode';
  static const String COUNTRY_CODE = 'countryCode';

  Locale _locale = const Locale('en');
  Locale get locale => _locale;

  LanguageProvider() {
    _loadFromPrefs();
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString(LANGUAGE_CODE) ?? 'en';
    final countryCode = prefs.getString(COUNTRY_CODE);

    _locale = Locale(languageCode, countryCode);
    notifyListeners();
  }

  Future<void> setLocale(Locale locale) async {
    if (locale == _locale) return;

    _locale = locale;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(LANGUAGE_CODE, locale.languageCode);
    await prefs.setString(COUNTRY_CODE, locale.countryCode ?? '');
  }

  Future<void> clearLocale() async {
    _locale = const Locale('en');
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(LANGUAGE_CODE);
    await prefs.remove(COUNTRY_CODE);
  }
} 