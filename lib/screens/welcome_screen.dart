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

  // Helper method to build a weather information card
  Widget _buildWeatherCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green[50], // Very light green background for weather card
        borderRadius: BorderRadius.circular(16), // Rounded corners
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 4), // Subtle shadow
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center, // Center content vertically
        children: [
          Icon(
            Icons.cloud, // Placeholder weather icon
            size: 50, // Adjusted size for grid
            color: Colors.green[700], // Darker green for icon
          ),
          const SizedBox(height: 8),
          Text(
            '28°C', // Placeholder temperature
            style: TextStyle(
              fontSize: 36, // Adjusted size for grid
              fontWeight: FontWeight.bold, // Bold sans-serif
              color: Colors.green[800], // Dark green for temperature
            ),
          ),
          Text(
            appStrings.get('weather_condition_cloudy'), // Placeholder localized condition
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16, // Adjusted size for grid
              fontWeight: FontWeight.normal, // Regular sans-serif
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to build a map information card
  Widget _buildMapCard(BuildContext context) {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(appStrings.get('map_implementation_note')), // Localized message
            backgroundColor: Colors.blueGrey,
            duration: const Duration(seconds: 4),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.blueGrey[50], // Light blue-grey background for map card
          borderRadius: BorderRadius.circular(16), // Rounded corners
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 2,
              blurRadius: 8,
              offset: const Offset(0, 4), // Subtle shadow
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.map, // Map icon
              size: 50, // Adjusted size for grid
              color: Colors.blue[700], // Blue for map icon
            ),
            const SizedBox(height: 8),
            Text(
              appStrings.get('current_location'), // Localized "Current Location"
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold, // Bold sans-serif
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 5),
            Expanded(
              child: Container(
                // Visually suggestive map background
                decoration: BoxDecoration(
                  color: Colors.blueGrey[100], // Slightly darker grey for map area
                  borderRadius: BorderRadius.circular(8),
                  image: const DecorationImage(
                    // Changed URL to explicitly request a PNG image from placehold.co
                    image: NetworkImage(
                      'https://placehold.co/150x150/E0E0E0/616161.png?text=Map+Placeholder', // Placeholder image
                    ),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Center(
                  child: Text(
                    appStrings.get('tap_to_view_map'), // Localized "Tap to view map"
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey[800],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 5),
            Text(
              appStrings.get('weather_location_placeholder'), // Re-use location text
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.normal, // Regular sans-serif
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white, // White background for the content
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              appStrings.get('welcome_to_app'), // Localized
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold, // Bold sans-serif for heading
                color: Colors.black87, // Dark color for text
              ),
            ),
            const SizedBox(height: 40),
            Expanded( // Allows the GridView to take available space
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: GridView.count(
                  crossAxisCount: 2, // 2 columns
                  crossAxisSpacing: 16, // Spacing between columns
                  mainAxisSpacing: 16, // Spacing between rows
                  childAspectRatio: 1.0, // Make cells roughly square
                  shrinkWrap: true, // Allows GridView to be inside a Column
                  physics: const NeverScrollableScrollPhysics(), // Prevents independent scrolling
                  children: [
                    _buildWeatherCard(context),
                    _buildMapCard(context),
                    // You can add two more cards here to complete a 2x2 grid
                    // For example:
                    // _buildEmptyCard(context, 'Quick Links', Icons.link),
                    // _buildEmptyCard(context, 'Notifications', Icons.notifications),
                  ],
                ),
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
                backgroundColor: Colors.green[800], // Dark green button
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 30), // Increased padding
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12), // Rounded corners
                ),
                elevation: 4, // Subtle shadow
                textStyle: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold, // Bold sans-serif for button text
                ),
              ),
              child: Text(
                appStrings.get('go_to_dashboard'), // Localized
              ),
            ),
          ],
        ),
      ),
    );
  }
}
