import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Import the package
import 'home_screen.dart';
import 'profile_update_screen.dart';
import 'app_localizations.dart'; // Import AppLocalizations

class SharedScaffold extends StatefulWidget {
  final Widget body;
  final String title;
  final int currentIndex;
  final void Function(int) onTabTapped;

  const SharedScaffold({
    super.key,
    required this.body,
    required this.title,
    required this.currentIndex,
    required this.onTabTapped,
  });

  @override
  State<SharedScaffold> createState() => _SharedScaffoldState();
}

class _SharedScaffoldState extends State<SharedScaffold> {
  // The future now holds a nullable DocumentSnapshot
  late Future<DocumentSnapshot?> _userDataFuture;
  AppLocalizations? _appStrings; // Added AppLocalizations instance
  String _selectedLanguage = 'en'; // Track selected language

  @override
  void initState() {
    super.initState();
    _loadSelectedLanguageAndUserData(); // Load language and user data
  }

  // Load selected language from SharedPreferences and then user data.
  Future<void> _loadSelectedLanguageAndUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final String? savedLanguage = prefs.getString('app_language');
    setState(() {
      _selectedLanguage = savedLanguage ?? 'en';
    });
    await _loadAppStrings(_selectedLanguage); // Load strings for the selected language
    _userDataFuture = _fetchUserData(); // Then fetch user data
    setState(() {}); // Trigger rebuild after data is ready
  }

  // Asynchronously loads the AppLocalizations for a given locale.
  Future<void> _loadAppStrings(String locale) async {
    final loadedStrings = await AppLocalizations.load(locale);
    setState(() {
      _appStrings = loadedStrings; // Update the localized strings
    });
  }

  // Fetches the phone number from SharedPreferences and then gets the user document
  Future<DocumentSnapshot?> _fetchUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Fetch the phone number using the key 'logged_in_phone'
      // final String? phoneNumber = prefs.getString('logged_in_phone');
      final String? phoneNumber = "+919566859696"; // Using the hardcoded number for demonstration as per previous files

      // If no phone number is found, return null to prevent errors
      if (phoneNumber == null || phoneNumber.isEmpty) {
        print("Phone number not found in local storage.");
        return null;
      }

      // Use the retrieved phone number to fetch data from Firestore
      return await FirebaseFirestore.instance.collection('farmers').doc(phoneNumber).get();
    } catch (e) {
      print("Error fetching user data: $e");
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show a loading indicator if appStrings are not yet loaded
    if (_appStrings == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // The FutureBuilder's type is updated to handle a nullable snapshot
    return FutureBuilder<DocumentSnapshot?>(
      future: _userDataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Check if data exists and the document is found in Firestore
        if (snapshot.hasData && snapshot.data != null && snapshot.data!.exists) {
          final userData = snapshot.data!.data() as Map<String, dynamic>;
          return _buildScaffold(context, userData);
        }

        // If no phone number was found or the document doesn't exist,
        // build the scaffold with default placeholder data.
        return _buildScaffold(context, null);
      },
    );
  }

  // This helper method remains the same, handling both real and placeholder data
  Widget _buildScaffold(BuildContext context, Map<String, dynamic>? userData) {
    final String firstName = userData?['first_name'] ?? 'User';
    final String lastName = userData?['last_name'] ?? '';
    final String fullName = '$firstName $lastName'.trim();
    final String email = userData?['email'] ?? 'user@example.com';
    final String? profileImageUrl = userData?['profile_image_url'];

    // Localized titles for bottom navigation bar items
    final List<String> bottomNavLabels = [
      _appStrings!.get('dashboard'),
      _appStrings!.get('messages'),
      _appStrings!.get('alerts'),
      _appStrings!.get('profile'),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title), // AppBar title is passed from parent
        backgroundColor: Colors.green[700],
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Row(
              children: [
                Text(
                  firstName, // User's name is dynamic, not localized
                  style: const TextStyle(fontSize: 16, color: Colors.white),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.grey.shade300,
                  backgroundImage: profileImageUrl != null
                      ? NetworkImage(profileImageUrl)
                      : null,
                  child: profileImageUrl == null
                      ? const Icon(Icons.person, size: 20)
                      : null,
                ),
              ],
            ),
          )
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(fullName), // User's name is dynamic
              accountEmail: Text(email), // User's email is dynamic
              currentAccountPicture: CircleAvatar(
                radius: 30,
                backgroundColor: Colors.white,
                child: ClipOval(
                  child: profileImageUrl != null
                      ? Image.network(
                          profileImageUrl,
                          fit: BoxFit.cover,
                          width: 90,
                          height: 90,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(Icons.person, size: 40);
                          },
                        )
                      : const Icon(Icons.person, size: 40),
                ),
              ),
              decoration: const BoxDecoration(color: Colors.green),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: Text(_appStrings!.get("home")), // Localized
              onTap: () {
                Navigator.pop(context);
                widget.onTabTapped(0);
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: Text(_appStrings!.get("settings")), // Localized
              onTap: () {
                // Handle settings tap
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: Text(_appStrings!.get("logout")), // Localized
              onTap: () {
                // Handle logout tap
              },
            ),
            // Language selection dropdown in the drawer
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: DropdownButtonFormField<String>(
                value: _selectedLanguage,
                decoration: InputDecoration(
                  labelText: _appStrings!.get("select_language"), // Localized label
                  border: const OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.grey[200],
                ),
                onChanged: (String? newValue) async {
                  if (newValue != null) {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setString('app_language', newValue);
                    // Reload the entire app to apply language changes
                    // This is a common approach for full app language changes
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const HomeScreen()), // Navigate to a fresh instance
                    );
                  }
                },
                items: AppLocalizations.supportedLocales
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(AppLocalizations.getLanguageName(value)),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
      body: widget.body,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: widget.currentIndex,
        selectedItemColor: Colors.green[800],
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          if (widget.currentIndex == index) {
            Navigator.popUntil(context, (route) => route.isFirst);
            return;
          }
          switch (index) {
            case 0:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const HomeScreen()),
              );
              break;
            case 3:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const ProfileUpdateScreen()),
              );
              break;
            default:
              widget.onTabTapped(index);
          }
        },
        items: [
          BottomNavigationBarItem(icon: const Icon(Icons.dashboard), label: bottomNavLabels[0]),
          BottomNavigationBarItem(icon: const Icon(Icons.message), label: bottomNavLabels[1]),
          BottomNavigationBarItem(icon: const Icon(Icons.notifications), label: bottomNavLabels[2]),
          BottomNavigationBarItem(icon: const Icon(Icons.person), label: bottomNavLabels[3]),
        ],
      ),
    );
  }
}
