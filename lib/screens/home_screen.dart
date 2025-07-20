import 'package:flutter/material.dart';
import 'agent_screen.dart';
import 'shared_scaffold.dart'; // Import the shared scaffold

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  // Titles for the AppBar corresponding to each tab
  final List<String> _titles = const [
    'Dashboard',
    'Messages',
    'Alerts',
    'Profile',
  ];

  // The list of screens to be displayed for each tab
  final List<Widget> _screens = [
    const DashboardContent(), // Your original home screen content
    const Center(child: Text('Messages Screen')), // Placeholder for Messages
    const Center(child: Text('Alerts Screen')),    // Placeholder for Alerts
    const Center(child: Text('Profile Screen')),   // Placeholder for Profile
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

// The original body content of your HomeScreen
class DashboardContent extends StatelessWidget {
  const DashboardContent({super.key});

  void _navigateTo(BuildContext context, String title) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AgentScreen(agentTitle: title)),
    );
  }

  Widget _buildCard(BuildContext context, String title, IconData icon, Color color) {
    return GestureDetector(
      onTap: () => _navigateTo(context, title),
      child: Card(
        color: Colors.white.withOpacity(0.9),
        elevation: 6,
        margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: color.withOpacity(0.1),
                child: Icon(icon, size: 30, color: color),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
            'assets/images/truck.jpg', // Ensure this image exists in your assets
            fit: BoxFit.cover,
            color: Colors.black.withOpacity(0.3),
            colorBlendMode: BlendMode.darken,
          ),
        ),
        ListView(
          padding: const EdgeInsets.symmetric(vertical: 40),
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.0),
              child: Text(
                "Choose Your Assistant",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 20),
            _buildCard(context, 'Agronomist', Icons.agriculture, Colors.green),
            _buildCard(context, 'Market Analyst', Icons.bar_chart, Colors.orange),
            _buildCard(context, 'Scheme Navigator', Icons.map, Colors.blue),
          ],
        ),
      ],
    );
  }
}