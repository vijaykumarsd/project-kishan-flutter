import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase Auth

import 'home_screen.dart';
import 'profile_update_screen.dart';
import 'app_localizations.dart';
import 'login_screen.dart'; // Import LoginScreen

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
  late Future<DocumentSnapshot?> _userDataFuture;
  AppLocalizations? _appStrings;
  String _selectedLanguage = 'en';

  @override
  void initState() {
    super.initState();
    _loadSelectedLanguageAndUserData();
  }

  Future<void> _loadSelectedLanguageAndUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final String? savedLanguage = prefs.getString('app_language');
    setState(() {
      _selectedLanguage = savedLanguage ?? 'en';
    });
    await _loadAppStrings(_selectedLanguage);
    _userDataFuture = _fetchUserData();
    setState(() {});
  }

  Future<void> _loadAppStrings(String locale) async {
    final loadedStrings = await AppLocalizations.load(locale);
    setState(() {
      _appStrings = loadedStrings;
    });
  }

  Future<DocumentSnapshot?> _fetchUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? phoneNumber = prefs.getString('logged_in_phone');
      // Using the hardcoded number for demonstration as per previous files if needed
      // final String? phoneNumber = "+919566859696"; 

      if (phoneNumber == null || phoneNumber.isEmpty) {
        print("Phone number not found in local storage.");
        return null;
      }
      return await FirebaseFirestore.instance.collection('farmers').doc(phoneNumber).get();
    } catch (e) {
      print("Error fetching user data: $e");
      return null;
    }
  }

  // --- New Logout Method ---
  Future<void> _logout() async {
    try {
      // Sign out from Firebase Authentication
      await FirebaseAuth.instance.signOut();

      // Clear the logged_in_phone from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('logged_in_phone');
      print("User logged out and phone number cleared from SharedPreferences.");

      // Navigate to the LoginScreen and remove all previous routes
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (Route<dynamic> route) => false, // This ensures all previous routes are removed
        );
      }
    } catch (e) {
      print("Error during logout: $e");
      // Optionally show a SnackBar or dialog to the user about logout failure
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_appStrings!.get("error") + " " + e.toString()), // Localized error message
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_appStrings == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return FutureBuilder<DocumentSnapshot?>(
      future: _userDataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData && snapshot.data != null && snapshot.data!.exists) {
          final userData = snapshot.data!.data() as Map<String, dynamic>;
          return _buildScaffold(context, userData);
        }

        return _buildScaffold(context, null);
      },
    );
  }

  Widget _buildScaffold(BuildContext context, Map<String, dynamic>? userData) {
    final String firstName = userData?['first_name'] ?? 'User';
    final String lastName = userData?['last_name'] ?? '';
    final String fullName = '$firstName $lastName'.trim();
    final String email = userData?['email'] ?? 'user@example.com';
    final String? profileImageUrl = userData?['profile_image_url'];

    final List<String> bottomNavLabels = [
      _appStrings!.get('dashboard'),
      _appStrings!.get('messages'),
      _appStrings!.get('alerts'),
      _appStrings!.get('profile'),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold, // Bold sans-serif for heading
          ),
        ),
        backgroundColor: Colors.green[800], // Dark green app bar
        foregroundColor: Colors.white,
        elevation: 4, // Subtle shadow
        iconTheme: const IconThemeData(color: Colors.white), // Ensure drawer icon is white
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Row(
              children: [
                Text(
                  firstName,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.normal, // Regular sans-serif
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.green[100], // Light green for avatar background
                  backgroundImage: profileImageUrl != null
                      ? NetworkImage(profileImageUrl)
                      : null,
                  child: profileImageUrl == null
                      ? Icon(Icons.person, size: 20, color: Colors.green[700]) // Darker green for icon
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
              accountName: Text(
                fullName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold, // Bold sans-serif
                  fontSize: 18,
                  color: Colors.white,
                ),
              ),
              accountEmail: Text(
                email,
                style: const TextStyle(
                  fontWeight: FontWeight.normal, // Regular sans-serif
                  color: Colors.white70,
                ),
              ),
              currentAccountPicture: CircleAvatar(
                radius: 30,
                backgroundColor: Colors.green[100], // Light green for avatar background
                child: ClipOval(
                  child: profileImageUrl != null
                      ? Image.network(
                          profileImageUrl,
                          fit: BoxFit.cover,
                          width: 90,
                          height: 90,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(Icons.person, size: 40, color: Colors.green[700]);
                          },
                        )
                      : Icon(Icons.person, size: 40, color: Colors.green[700]),
                ),
              ),
              decoration: BoxDecoration(color: Colors.green[800]), // Dark green for drawer header
            ),
            ListTile(
              leading: Icon(Icons.home, color: Colors.green[700]),
              title: Text(
                _appStrings!.get("home"),
                style: const TextStyle(fontWeight: FontWeight.normal, color: Colors.black87), // Regular sans-serif
              ),
              onTap: () {
                Navigator.pop(context);
                widget.onTabTapped(0);
              },
            ),
            ListTile(
              leading: Icon(Icons.settings, color: Colors.green[700]),
              title: Text(
                _appStrings!.get("settings"),
                style: const TextStyle(fontWeight: FontWeight.normal, color: Colors.black87), // Regular sans-serif
              ),
              onTap: () {
                // Handle settings tap
              },
            ),
            ListTile(
              leading: Icon(Icons.logout, color: Colors.red[700]), // Red icon for logout
              title: Text(
                _appStrings!.get("logout"), // Localized logout text
                style: TextStyle(fontWeight: FontWeight.normal, color: Colors.red[700]), // Regular sans-serif
              ),
              onTap: _logout, // Call the new logout method
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: DropdownButtonFormField<String>(
                value: _selectedLanguage,
                decoration: InputDecoration(
                  labelText: _appStrings!.get("select_language"),
                  labelStyle: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.normal),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12), // Rounded corners
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey[100], // Light grey fill
                  contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                ),
                style: const TextStyle(fontWeight: FontWeight.normal, color: Colors.black87),
                iconEnabledColor: Colors.green[700],
                onChanged: (String? newValue) async {
                  if (newValue != null) {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setString('app_language', newValue);
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const HomeScreen()),
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
        selectedItemColor: Colors.green[800], // Dark green for selected item
        unselectedItemColor: Colors.grey,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold), // Bold for selected label
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal), // Regular for unselected label
        type: BottomNavigationBarType.fixed, // Ensure all labels are visible
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

