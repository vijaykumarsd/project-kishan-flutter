import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'shared_scaffold.dart';
import 'app_localizations.dart'; // Import AppLocalizations
import 'package:shared_preferences/shared_preferences.dart'; // Import for SharedPreferences
import 'package:intl/intl.dart'; // For date formatting

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> with WidgetsBindingObserver {
  int _currentIndex = 0;
  AppLocalizations? _appStrings; // Added AppLocalizations instance
  String _selectedLanguage = 'en'; // Track selected language

  @override
  void initState() {
    super.initState();
    _loadSelectedLanguage(); // Load language when the screen initializes
    WidgetsBinding.instance.addObserver(this); // Add observer to listen for lifecycle changes
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this); // Remove observer when the widget is disposed
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // This method is called when the app's lifecycle state changes.
    // We are interested when the app comes back to the foreground ('resumed').
    if (state == AppLifecycleState.resumed) {
      _loadSelectedLanguage(); // Re-load language to pick up any changes
    }
  }

  // Asynchronously loads the selected language from SharedPreferences.
  Future<void> _loadSelectedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedLanguage = prefs.getString('app_language') ?? 'en';
    });
    // Ensure that _appStrings is updated after loading the new language
    await _loadAppStrings(_selectedLanguage);
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
      Center(child: Text(_appStrings!.get('messages'))), // Placeholder localized
      Center(child: Text(_appStrings!.get('alerts'))), // Placeholder localized
      Center(child: Text(_appStrings!.get('profile'))),  // Placeholder localized
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

  // Sample weather data based on the provided JSON
  final Map<String, dynamic> weatherData = const {
    "current": {
      "temperature": 21.3,
      "condition": "Partly cloudy",
      "wind_kph": 29.5,
      "precip_mm": 0,
      "pressure_mb": 1013
    },
    "forecast": [
      {
        "date": "2025-07-26",
        "avg_temp": 21.1,
        "condition": "Patchy rain nearby",
        "icon_code": "176.png"
      },
      {
        "date": "2025-07-27",
        "avg_temp": 21.6,
        "condition": "Patchy rain nearby",
        "icon_code": "176.png"
      },
      {
        "date": "2025-07-28",
        "avg_temp": 22,
        "condition": "Patchy rain nearby",
        "icon_code": "176.png"
      },
      {
        "date": "2025-07-29",
        "avg_temp": 22.6,
        "condition": "Patchy rain nearby",
        "icon_code": "176.png"
      },
      {
        "date": "2025-07-30",
        "avg_temp": 22.7,
        "condition": "Partly Cloudy ",
        "icon_code": "116.png"
      }
    ],
    "location": {
      "country": "India",
      "region": "Karnataka",
      "lat": 12.9833,
      "lon": 77.5833,
      "localtime": "2025-07-26 20:21",
      "timezone": "Asia/Kolkata"
    },
    "astro": {
      "sunrise": "06:04 AM",
      "sunset": "06:48 PM"
    }
  };

  // Helper to get icon based on condition (simplified for demonstration)
  IconData _getWeatherIcon(String condition) {
    if (condition.toLowerCase().contains('cloudy')) {
      return Icons.cloud;
    } else if (condition.toLowerCase().contains('rain')) {
      return Icons.cloudy_snowing; // Using this as a generic rain/snow icon
    } else if (condition.toLowerCase().contains('sun') || condition.toLowerCase().contains('clear')) {
      return Icons.wb_sunny;
    }
    return Icons.cloud; // Default
  }

  // Helper method to build the Weather Outlook card
  Widget _buildWeatherOutlookCard(BuildContext context) {
    final current = weatherData['current'];
    final forecast = weatherData['forecast'] as List<dynamic>;

    return Card(
      elevation: 8, // Subtle shadow
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), // Rounded corners
      margin: EdgeInsets.zero, // No external margin, controlled by padding in parent
      color: const Color(0xFF1A237E), // Dark blue background for weather card
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              appStrings.get('Weather Outlook'), // Localized "Weather Outlook"
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold, // Bold sans-serif
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Icon(
                  _getWeatherIcon(current['condition']),
                  size: 60,
                  color: Colors.white,
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        current['condition'],
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.normal, // Regular sans-serif
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        '${current['temperature']}°C',
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold, // Bold sans-serif
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${appStrings.get('Wind')}: ${current['wind_kph']} kph', // Localized 'Wind'
                      style: const TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    Text(
                      '${appStrings.get('Precip')}: ${current['precip_mm']} mm', // Localized 'Precip'
                      style: const TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    Text(
                      '${appStrings.get('Pressure')}: ${current['pressure_mb']} mb', // Localized 'Pressure'
                      style: const TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Forecast section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: forecast.take(5).map((day) {
                final date = DateTime.parse(day['date']);
                final dayOfWeek = DateFormat('EEE', appStrings.locale).format(date); // Localize day of week
                return Column(
                  children: [
                    Text(
                      dayOfWeek,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                    const SizedBox(height: 5),
                    Icon(
                      _getWeatherIcon(day['condition']),
                      size: 30,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${day['avg_temp']}°C',
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ],
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to build the Information card
  Widget _buildInformationCard(BuildContext context) {
    final locationData = weatherData['location'];
    final astroData = weatherData['astro'];

    return Card(
      elevation: 8, // Subtle shadow
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), // Rounded corners
      margin: EdgeInsets.zero, // No external margin, controlled by padding in parent
      color: Colors.white, // White background for information card
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              appStrings.get('Information'), // Localized "Information"
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold, // Bold sans-serif
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            _buildInfoRow(appStrings.get('Country'), locationData['country']),
            _buildInfoRow(appStrings.get('Region'), locationData['region']),
            // _buildInfoRow(appStrings.get('lat_lon'), '${locationData['lat']}, ${locationData['lon']}'),
            // _buildInfoRow(appStrings.get('current_time'), locationData['localtime'].split(' ')[1]), // Extract time
            _buildInfoRow(appStrings.get('Timezone_id'), locationData['timezone']),
            _buildInfoRow(appStrings.get('Sunrise'), astroData['sunrise']),
            _buildInfoRow(appStrings.get('Sunset'), astroData['sunset']),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.normal, // Regular sans-serif
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold, // Bold sans-serif for value
                color: Colors.black87,
              ),
            ),
          ),
        ],
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
            Expanded( // Allows the Row to take available space
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch, // Make cards stretch to same height
                  children: [
                    Expanded(
                      child: _buildWeatherOutlookCard(context),
                    ),
                    const SizedBox(width: 16), // Spacing between cards
                    Expanded(
                      child: _buildInformationCard(context),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const HomeScreen()),
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
            const SizedBox(height: 20), // Add some space at the bottom
          ],
        ),
      ),
    );
  }
}