// import 'package:flutter/material.dart';

// class WelcomeScreen extends StatelessWidget {
//   const WelcomeScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       // appBar: AppBar(title: const Text("Welcome")),
//       appBar: AppBar(
//   title: const Text("Welcome to Kisan App"),
//   backgroundColor: Colors.green[700],
// ),
// backgroundColor: Colors.green[50],
//       body: const Center(
//         child: Text("Welcome to Kisan App!", style: TextStyle(fontSize: 20)),
//       ),
//     );
//   }
// }


import 'package:flutter/material.dart';
import 'home_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Welcome'), backgroundColor: Colors.green[700]),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
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
      ),
    );
  }
}
