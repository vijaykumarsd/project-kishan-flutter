import 'package:flutter/material.dart';
import 'screens/login_screen.dart';

void main() {
  runApp(const KisanApp());
}

class KisanApp extends StatelessWidget {
  const KisanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kisan App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.green),
      home: const LoginScreen(), // Start with Login
    );
  }
}
