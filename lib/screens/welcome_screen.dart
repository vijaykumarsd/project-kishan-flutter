import 'package:flutter/material.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(title: const Text("Welcome")),
      appBar: AppBar(
  title: const Text("Welcome to Kisan App"),
  backgroundColor: Colors.green[700],
),
backgroundColor: Colors.green[50],
      body: const Center(
        child: Text("Welcome to Kisan App!", style: TextStyle(fontSize: 20)),
      ),
    );
  }
}
