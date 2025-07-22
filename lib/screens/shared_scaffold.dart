import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Import the package
import 'home_screen.dart';
import 'profile_update_screen.dart';

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

  @override
  void initState() {
    super.initState();
    _userDataFuture = _fetchUserData();
  }

  // Fetches the phone number from SharedPreferences and then gets the user document
  Future<DocumentSnapshot?> _fetchUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Fetch the phone number using the key 'logged_in_phone'
      // final String? phoneNumber = prefs.getString('logged_in_phone');
      final String? phoneNumber = "+919566859696";

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

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.green[700],
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Row(
              children: [
                Text(
                  firstName,
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
              accountName: Text(fullName),
              accountEmail: Text(email),
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
              title: const Text("Home"),
              onTap: () {
                Navigator.pop(context);
                widget.onTabTapped(0);
              },
            ),
            const ListTile(
              leading: Icon(Icons.settings),
              title: Text("Settings"),
            ),
            const ListTile(
              leading: Icon(Icons.logout),
              title: Text("Logout"),
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
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.message), label: 'Messages'),
          BottomNavigationBarItem(icon: Icon(Icons.notifications), label: 'Alerts'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}