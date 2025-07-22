import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'shared_scaffold.dart';
import 'app_localizations.dart'; // Import AppLocalizations
import 'package:shared_preferences/shared_preferences.dart'; // Import for SharedPreferences

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  int _currentIndex = 0;
  AppLocalizations? _appStrings; // Added AppLocalizations instance
  String _selectedLanguage = 'en'; // Track selected language

  @override
  void initState() {
    super.initState();
    _loadSelectedLanguage(); // Load language when the screen initializes
  }

  // Asynchronously loads the selected language from SharedPreferences.
  Future<void> _loadSelectedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedLanguage = prefs.getString('app_language') ?? 'en';
    });
    await _loadAppStrings(_selectedLanguage); // Load strings for the selected language
  }

  // Asynchronously loads the AppLocalizations for a given locale.
  Future<void> _loadAppStrings(String locale) async {
    final loadedStrings = await AppLocalizations.load(locale);
    setState(() {
      _appStrings = loadedStrings; // Update the localized strings
    });
  }

  // Placeholder screens for the other bottom navigation tabs
  // These will now be localized using _appStrings
  List<Widget> _getScreens() {
    if (_appStrings == null) {
      return [
        const Center(child: CircularProgressIndicator()),
        const Center(child: CircularProgressIndicator()),
        const Center(child: CircularProgressIndicator()),
        const Center(child: CircularProgressIndicator()),
      ];
    }
    return [
      WelcomeContent(appStrings: _appStrings!), // Pass appStrings to WelcomeContent
      Center(child: Text(_appStrings!.get('messages') + ' ' + _appStrings!.get('profile'))), // Placeholder localized
      Center(child: Text(_appStrings!.get('alerts') + ' ' + _appStrings!.get('profile'))),    // Placeholder localized
      Center(child: Text(_appStrings!.get('profile') + ' ' + _appStrings!.get('profile'))),   // Placeholder localized
    ];
  }

  // Titles for the AppBar corresponding to each tab, now localized
  List<String> _getTitles() {
    if (_appStrings == null) {
      return const ['Loading...', 'Loading...', 'Loading...', 'Loading...'];
    }
    return [
      _appStrings!.get('welcome'),
      _appStrings!.get('messages'),
      _appStrings!.get('alerts'),
      _appStrings!.get('profile'),
    ];
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_appStrings == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return SharedScaffold(
      title: _getTitles()[_currentIndex],
      currentIndex: _currentIndex,
      onTabTapped: _onTabTapped,
      body: _getScreens()[_currentIndex],
    );
  }
}

// Extracted the main content of the welcome screen for clarity
class WelcomeContent extends StatelessWidget {
  final AppLocalizations appStrings; // Receive AppLocalizations
  const WelcomeContent({super.key, required this.appStrings});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white, // A neutral background for the content
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              appStrings.get('welcome_to_app'), // Localized
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const HomeScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[800],
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 30),
              ),
              child: Text(
                appStrings.get('go_to_dashboard'), // Localized
                style: const TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
