import 'package:flutter/material.dart';
import 'screens/registration_screen.dart';

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
      home: const RegistrationScreen(),
    );
  }
}
