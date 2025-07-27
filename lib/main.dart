import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_localizations/flutter_localizations.dart'; // Import for localization delegates
import 'firebase_options.dart'; // Generated automatically
import 'screens/language_selection_screen.dart'; // Import the new LanguageSelectionScreen
import 'screens/app_localizations.dart'; // Import AppLocalizations

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
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
      // Add localization delegates
      localizationsDelegates: const [
        AppLocalizations.delegate, // Your custom delegate
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      // Define supported locales
      supportedLocales: AppLocalizations.supportedLocales.map((localeCode) => Locale(localeCode)).toList(),
      // Set LanguageSelectionScreen as the initial home screen
      home: const LanguageSelectionScreen(),
    );
  }
}
