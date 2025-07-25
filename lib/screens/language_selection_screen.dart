import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_localizations.dart';
import 'login_screen.dart';

class LanguageSelectionScreen extends StatefulWidget {
  const LanguageSelectionScreen({super.key});

  @override
  State<LanguageSelectionScreen> createState() => _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends State<LanguageSelectionScreen> {
  String _selectedLanguage = 'en';
  AppLocalizations? _appStrings;

  @override
  void initState() {
    super.initState();
    _loadInitialLanguageAndStrings();
  }

  Future<void> _loadInitialLanguageAndStrings() async {
    final prefs = await SharedPreferences.getInstance();
    final String savedLanguage = prefs.getString('app_language') ?? 'en';
    setState(() {
      _selectedLanguage = savedLanguage;
    });
    await _loadAppStrings(savedLanguage);
  }

  Future<void> _loadAppStrings(String locale) async {
    final loadedStrings = await AppLocalizations.load(locale);
    setState(() {
      _appStrings = loadedStrings;
    });
  }

  void _onLanguageSelected(String languageCode) async {
    if (languageCode != _selectedLanguage) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('app_language', languageCode);
      setState(() {
        _selectedLanguage = languageCode;
      });
      await _loadAppStrings(languageCode);
    }
  }

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
      (Route<dynamic> route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_appStrings == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          _appStrings!.get('select_language'),
          style: const TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: GridView.builder(
               gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 160, // max width of each card (in pixels)
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 0.8,   // height will adjust automatically
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
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(
                          color: isSelected ? Colors.green.shade700 : Colors.grey.shade300,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Stack(
                        children: [
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 6.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    _appStrings!.get('${localeCode}_short'),
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: isSelected ? Colors.green.shade800 : Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    AppLocalizations.getLanguageName(localeCode),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isSelected ? Colors.green.shade700 : Colors.black54,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (isSelected)
                            Positioned(
                              top: 6,
                              right: 6,
                              child: Icon(
                                Icons.check_circle,
                                color: Colors.green.shade700,
                                size: 20,
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
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: _navigateToLoginScreen,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[700],
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(45),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              child: Text(_appStrings!.get('continue_button_text')),
            ),
          ),
        ],
      ),
    );
  }
}
