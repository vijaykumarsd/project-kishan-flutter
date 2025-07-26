import 'dart:convert';
import 'package:flutter/material.dart'; // Import for LocalizationsDelegate
import 'package:flutter/services.dart' show rootBundle;

// A class to manage application localizations (translations).
class AppLocalizations {
  final String locale; // The current locale code (e.g., 'en', 'hi', 'mr').
  Map<String, String> _localizedStrings = {}; // Map to store key-value translations.

  // Constructor for AppLocalizations.
  AppLocalizations(this.locale);

  // Static method to load translations for a given locale.
  static Future<AppLocalizations> load(String locale) async {
    final AppLocalizations appLocalizations = AppLocalizations(locale);
    // Load the JSON string from the assets folder.
    String jsonString = await rootBundle.loadString('assets/lang/$locale.json');
    // Decode the JSON string into a map.
    Map<String, dynamic> jsonMap = json.decode(jsonString);
    // Convert dynamic map to Map<String, String>.
    appLocalizations._localizedStrings =
        jsonMap.map((key, value) => MapEntry(key, value.toString()));
    return appLocalizations;
  }

  // Get the translated string for a given key.
  // If the key is not found, it returns the key itself as a fallback.
  String get(String key) {
    return _localizedStrings[key] ?? key;
  }

  // List of supported locale codes.
  static const List<String> supportedLocales = [
    'en', // English
    'hi', // Hindi
    'mr', // Marathi
    'ta', // Tamil
    'kn', // Kannada
    'te', // Telugu
    'ml'  // Malayalam
  ];

  // Helper method to get the display name of a language from its locale code.
  static String getLanguageName(String localeCode) {
    switch (localeCode) {
      case 'en':
        return 'English';
      case 'hi':
        return 'हिंदी'; // Hindi
      case 'mr':
        return 'मराठी'; // Marathi
      case 'ta':
        return 'தமிழ்'; // Tamil
      case 'kn':
        return 'ಕನ್ನಡ'; // Kannada
      case 'te':
        return 'తెలుగు'; // Telugu
      case 'ml':
        return 'മലയാളಂ'; // Malayalam
      default:
        return 'English'; // Default to English if locale code is unknown.
    }
  }

  // 🔹 New: LocalizationsDelegate for AppLocalizations
  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();
}

// 🔹 New: Private delegate class
class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    // Return true if the language code is in the list of supported locales.
    return AppLocalizations.supportedLocales.contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) {
    // Load your custom AppLocalizations for the given locale.
    return AppLocalizations.load(locale.languageCode);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
