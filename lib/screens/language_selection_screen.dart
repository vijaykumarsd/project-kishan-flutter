import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_localizations.dart'; // Make sure this path is correct
import 'login_screen.dart'; // Make sure this path is correct

class LanguageSelectionScreen extends StatefulWidget {
  const LanguageSelectionScreen({super.key});

  @override
  State<LanguageSelectionScreen> createState() => _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends State<LanguageSelectionScreen> {
  String _selectedLanguage = 'en'; // Default to English
  AppLocalizations? _appStrings; // Holds the loaded localized strings

  @override
  void initState() {
    super.initState();
    _loadInitialLanguageAndStrings();
  }

  // Load the initial language (if saved) and then the corresponding strings
  Future<void> _loadInitialLanguageAndStrings() async {
    final prefs = await SharedPreferences.getInstance();
    final String savedLanguage = prefs.getString('app_language') ?? 'en';
    setState(() {
      _selectedLanguage = savedLanguage;
    });
    await _loadAppStrings(savedLanguage);
  }

  // Asynchronously loads the AppLocalizations for a given locale.
  Future<void> _loadAppStrings(String locale) async {
    final loadedStrings = await AppLocalizations.load(locale);
    setState(() {
      _appStrings = loadedStrings;
    });
  }

  // Handles language change and saves to SharedPreferences
  void _onLanguageSelected(String languageCode) async {
    if (languageCode != _selectedLanguage) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('app_language', languageCode);
      setState(() {
        _selectedLanguage = languageCode;
      });
      await _loadAppStrings(languageCode); // Reload strings for the new language
    }
  }

  // Navigates to the LoginScreen
  void _navigateToLoginScreen() {
    if (_appStrings == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please wait, loading language data...")),
      );
      return;
    }

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (Route<dynamic> route) => false, // Remove all previous routes
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_appStrings == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()), // Show loading until strings are ready
      );
    }

    return Scaffold(
      backgroundColor: Colors.white, // Plain white background as per image
      appBar: AppBar(
        title: Text(
          _appStrings!.get('select_language'), // Localized "Select Language" title
          style: const TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0, // No shadow
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3, // 3 cards per row
                  crossAxisSpacing: 16.0,
                  mainAxisSpacing: 16.0,
                  childAspectRatio: 0.85, // Adjust aspect ratio for card height
                ),
                itemCount: AppLocalizations.supportedLocales.length,
                itemBuilder: (context, index) {
                  final localeCode = AppLocalizations.supportedLocales[index];
                  final isSelected = localeCode == _selectedLanguage;

                  return GestureDetector(
                    onTap: () => _onLanguageSelected(localeCode),
                    child: Card(
                      color: isSelected ? Colors.green.shade100 : Colors.white,
                      elevation: isSelected ? 4 : 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: isSelected ? Colors.green.shade700 : Colors.grey.shade300,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Stack(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _appStrings!.get('${localeCode}_short'), // Short language code/character
                                  style: TextStyle(
                                    fontSize: 48,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected ? Colors.green.shade800 : Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  AppLocalizations.getLanguageName(localeCode), // Full language name in its script
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: isSelected ? Colors.green.shade700 : Colors.black54,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Icon(
                                Icons.check_circle,
                                color: Colors.green.shade700,
                                size: 24,
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          // "Next" Button at the bottom
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: _navigateToLoginScreen,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[700],
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(50), // Full width button
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              child: Text(_appStrings!.get('continue_button_text')),
            ),
          ),
        ],
      ),
    );
  }
}
