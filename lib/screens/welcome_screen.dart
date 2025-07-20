import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'shared_scaffold.dart'; // Import the shared scaffold

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  int _currentIndex = 0;

  // Placeholder screens for the other bottom navigation tabs
  final List<Widget> _screens = [
    // The initial welcome content is handled directly in the body
    const WelcomeContent(),
    const Center(child: Text('Messages Screen')),
    const Center(child: Text('Alerts Screen')),
    const Center(child: Text('Profile Screen')),
  ];

  // Titles for the AppBar corresponding to each tab
  // THE FIX IS HERE: The erroneous 'al_alt_text' line has been removed.
  final List<String> _titles = const [
    'Welcome',
    'Messages',
    'Alerts',
    'Profile',
  ];

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SharedScaffold(
      title: _titles[_currentIndex],
      currentIndex: _currentIndex,
      onTabTapped: _onTabTapped,
      body: _screens[_currentIndex],
    );
  }
}

// Extracted the main content of the welcome screen for clarity
class WelcomeContent extends StatelessWidget {
  const WelcomeContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white, // A neutral background for the content
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Welcome to Agri-Assistant',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                // This will replace the WelcomeScreen with the HomeScreen
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const HomeScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[800],
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 30),
              ),
              child: const Text(
                'Go to Dashboard',
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}