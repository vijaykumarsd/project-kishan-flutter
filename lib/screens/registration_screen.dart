import 'package:flutter/material.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Import for SharedPreferences

import 'app_localizations.dart'; // Import the AppLocalizations class

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  String _fullPhoneNumber = '';

  String? _firstNameError;
  String? _lastNameError;

  String _selectedLanguage = 'en'; // Default language
  AppLocalizations? _appStrings; // Holds the loaded localized strings

  @override
  void initState() {
    super.initState();
    _loadSelectedLanguage(); // Load language when the screen initializes
  }

  // Asynchronously loads the selected language from SharedPreferences.
  // If no language is saved, it defaults to 'en' (English).
  Future<void> _loadSelectedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedLanguage = prefs.getString('app_language') ?? 'en';
    });
    await _loadAppStrings(_selectedLanguage); // Load strings for the selected language
  }

  // Asynchronously loads the AppLocalizations for a given locale.
  Future<void> _loadAppStrings(String locale) async {
    final loadedStrings = await AppLocalizations.load(locale);
    setState(() {
      _appStrings = loadedStrings; // Update the localized strings
    });
  }

  // Validates if the given name matches the regex pattern.
  bool isValidName(String name) {
    final nameRegex = RegExp(r'^[a-zA-Z]{2,}$');
    return nameRegex.hasMatch(name);
  }

  // Validates the first name and sets an error message if invalid.
  void _validateFirstName(String value) {
    if (_appStrings == null) return;
    setState(() {
      _firstNameError = isValidName(value) ? null : _appStrings!.get('enter_valid_first_name');
    });
  }

  // Validates the last name and sets an error message if invalid.
  void _validateLastName(String value) {
    if (_appStrings == null) return;
    setState(() {
      _lastNameError = isValidName(value) ? null : _appStrings!.get('enter_valid_last_name');
    });
  }

  // Handles the registration process, including validation and Firestore interaction.
  Future<void> _register() async {
    if (_appStrings == null) return; // Ensure strings are loaded

    final first = firstNameController.text.trim();
    final last = lastNameController.text.trim();
    final phone = _fullPhoneNumber.trim();

    // Final validation
    if (!isValidName(first) || !isValidName(last) || phone.isEmpty || phone.length <= 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _appStrings!.get("enter_valid_name_phone"),
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    try {
      final docRef = FirebaseFirestore.instance.collection('farmers').doc(phone);
      final existingDoc = await docRef.get();

      if (existingDoc.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _appStrings!.get("phone_already_registered"),
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      await docRef.set({
        'first_name': first,
        'last_name': last,
        'phone_number': phone,
        'registered_at': Timestamp.now(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _appStrings!.get("registration_successful"),
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("${_appStrings!.get("error")} ${e.toString()}"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show a loading indicator or empty container if strings are not yet loaded.
    if (_appStrings == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          // Full background image with dark overlay.
          Positioned.fill(
            child: Image.asset(
              'assets/images/farmer.jpg',
              fit: BoxFit.cover,
              color: Colors.black.withOpacity(0.4),
              colorBlendMode: BlendMode.darken,
            ),
          ),
          // Responsive, scrollable foreground content.
          LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Language selection dropdown.
                            Align(
                              alignment: Alignment.topRight,
                              child: DropdownButton<String>(
                                value: _selectedLanguage,
                                icon: const Icon(Icons.language, color: Colors.white),
                                underline: Container(), // Remove underline
                                onChanged: (String? newValue) async {
                                  if (newValue != null) {
                                    setState(() {
                                      _selectedLanguage = newValue;
                                    });
                                    final prefs = await SharedPreferences.getInstance();
                                    await prefs.setString('app_language', newValue); // Save selected language
                                    await _loadAppStrings(newValue); // Reload strings for new language
                                  }
                                },
                                items: AppLocalizations.supportedLocales
                                    .map<DropdownMenuItem<String>>((String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(
                                      AppLocalizations.getLanguageName(value),
                                      style: const TextStyle(color: Colors.white),
                                    ),
                                  );
                                }).toList(),
                                dropdownColor: Colors.black54, // Dark background for dropdown
                              ),
                            ),
                            const SizedBox(height: 20),
                            // Circular App Logo.
                            ClipOval(
                              child: Image.asset(
                                'assets/images/kisan_image.png',
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(height: 20),
                            // Farmer Registration title, now localized.
                            Text(
                              _appStrings!.get("farmer_registration"),
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 40),
                            // Constrained input fields and buttons.
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 400),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  TextField(
                                    controller: firstNameController,
                                    onChanged: _validateFirstName,
                                    style: const TextStyle(color: Colors.white),
                                    decoration: InputDecoration(
                                      labelText: _appStrings!.get("first_name"), // Localized label
                                      errorText: _firstNameError,
                                      labelStyle: const TextStyle(color: Colors.white),
                                      filled: true,
                                      fillColor: Colors.white.withOpacity(0.2),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  TextField(
                                    controller: lastNameController,
                                    onChanged: _validateLastName,
                                    style: const TextStyle(color: Colors.white),
                                    decoration: InputDecoration(
                                      labelText: _appStrings!.get("last_name"), // Localized label
                                      errorText: _lastNameError,
                                      labelStyle: const TextStyle(color: Colors.white),
                                      filled: true,
                                      fillColor: Colors.white.withOpacity(0.2),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  IntlPhoneField(
                                    decoration: InputDecoration(
                                      labelText: _appStrings!.get("mobile_number"), // Localized label
                                      filled: true,
                                      fillColor: Colors.white70,
                                      border: const OutlineInputBorder(),
                                    ),
                                    initialCountryCode: 'IN',
                                    keyboardType: TextInputType.phone,
                                    onChanged: (phone) {
                                      _fullPhoneNumber = phone.completeNumber;
                                    },
                                  ),
                                  const SizedBox(height: 24),
                                  ElevatedButton(
                                    onPressed: _register,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green[800],
                                      minimumSize: const Size.fromHeight(48),
                                    ),
                                    child: Text(
                                      _appStrings!.get("register"), // Localized button text
                                      style: const TextStyle(color: Colors.white),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: Text(
                                      _appStrings!.get("back_to_login"), // Localized link text
                                      style: const TextStyle(
                                        color: Colors.lightBlueAccent,
                                        decoration: TextDecoration.underline,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
