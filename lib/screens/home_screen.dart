import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _navigateTo(BuildContext context, String title) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AgentScreen(agentTitle: "Agri Agent")),
      // replace the agentTitle which come from BE
    );
  }

  Widget _buildCard(BuildContext context, String title, IconData icon, Color color) {
    return GestureDetector(
      onTap: () => _navigateTo(context, title),
      child: Card(
        elevation: 4,
        margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, size: 40, color: color),
              const SizedBox(width: 20),
              Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Welcome Farmer'),
        backgroundColor: Colors.green[700],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/images/kisan_image.png"),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          // overlay to improve readability
          color: Colors.white.withOpacity(0.8),
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 20),
            children: [
              _buildCard(context, 'Agronomist', Icons.agriculture, Colors.green),
              _buildCard(context, 'Market Analyst', Icons.bar_chart, Colors.orange),
              _buildCard(context, 'Scheme Navigator', Icons.map, Colors.blue),
            ],
          ),
        ),
      ),
    );
  }
}

// Temporary screen for each agent
class AgentScreen extends StatelessWidget {
  final String agentTitle;
  const AgentScreen({super.key, required this.agentTitle});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(agentTitle), backgroundColor: Colors.green[700]),
      body: Center(
        child: Text(
          'This is the $agentTitle screen',
          style: const TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
