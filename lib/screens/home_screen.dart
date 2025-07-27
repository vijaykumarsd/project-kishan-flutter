import 'package:flutter/material.dart';
import 'agent_screen.dart';
import 'shared_scaffold.dart';
import 'app_localizations.dart'; // Import AppLocalizations
import 'package:shared_preferences/shared_preferences.dart'; // Import for SharedPreferences

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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

  // Titles for the AppBar corresponding to each tab, now localized
  List<String> _getTitles() {
    if (_appStrings == null) {
      return const ['Loading...', 'Loading...', 'Loading...', 'Loading...'];
    }
    return [
      _appStrings!.get('dashboard'),
      _appStrings!.get('messages'),
      _appStrings!.get('alerts'),
      _appStrings!.get('profile'),
    ];
  }

  // The list of screens to be displayed for each tab, now localized
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
      DashboardContent(appStrings: _appStrings!), // Pass appStrings to DashboardContent
      Center(child: Text(_appStrings!.get('messages') + ' ' + _appStrings!.get('profile'))), // Placeholder localized
      Center(child: Text(_appStrings!.get('alerts') + ' ' + _appStrings!.get('profile'))),    // Placeholder localized
      Center(child: Text(_appStrings!.get('profile') + ' ' + _appStrings!.get('profile'))),   // Placeholder localized
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

// The original body content of your HomeScreen, now takes AppLocalizations
class DashboardContent extends StatelessWidget {
  final AppLocalizations appStrings; // Receive AppLocalizations
  const DashboardContent({super.key, required this.appStrings});

  void _navigateTo(BuildContext context, String title) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AgentScreen(agentTitle: title, appStrings: appStrings)), // Pass appStrings here
    );
  }

  Widget _buildCard(BuildContext context, String titleKey, IconData icon, Color color) {
    return GestureDetector(
      onTap: () => _navigateTo(context, appStrings.get(titleKey)), // Use localized title
      child: Card(
        color: Colors.white.withOpacity(0.95), // White background for cards
        elevation: 8, // Increased subtle shadow
        margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), // Rounded corners
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: color.withOpacity(0.15), // Slightly more vibrant background for icon
                child: Icon(icon, size: 30, color: color),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Text(
                  appStrings.get(titleKey), // Localized card title
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold, // Bold sans-serif for heading
                    color: Colors.black87,
                  ),
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            'assets/images/truck.jpg',
            fit: BoxFit.cover,
            color: Colors.black.withOpacity(0.3),
            colorBlendMode: BlendMode.darken,
          ),
        ),
        ListView(
          padding: const EdgeInsets.symmetric(vertical: 40),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Text(
                appStrings.get("choose_your_assistant"), // Localized
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold, // Bold sans-serif for heading
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 20),
            _buildCard(context, 'agronomist', Icons.agriculture, Colors.green), // Use key
            _buildCard(context, 'market_analyst', Icons.bar_chart, Colors.orange), // Use key
            _buildCard(context, 'Government Scheme Navigator', Icons.map, Colors.blue), // Use key
          ],
        ),
      ],
    );
  }
}
