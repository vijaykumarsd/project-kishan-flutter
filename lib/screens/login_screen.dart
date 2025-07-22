import 'package:flutter/material.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'registration_screen.dart';
import 'welcome_screen.dart';
import 'app_localizations.dart'; // Import the new AppLocalizations class

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  String _fullPhoneNumber = '';
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

  // Handles the login process, including phone number validation and OTP verification.
  void _login() async {
    if (_appStrings == null) return; // Ensure strings are loaded

    if (_fullPhoneNumber.isNotEmpty && _fullPhoneNumber.length > 8) {
      final snapshot = await FirebaseFirestore.instance
          .collection('farmers')
          .doc(_fullPhoneNumber)
          .get();

      if (!snapshot.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_appStrings!.get("mobile_number_not_found")),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }

      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: _fullPhoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto-verification on some devices (rare)
          await FirebaseAuth.instance.signInWithCredential(credential);
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('logged_in_phone', _fullPhoneNumber);
          _goToWelcomeScreen();
        },
        verificationFailed: (FirebaseAuthException e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("${_appStrings!.get("verification_failed")} ${e.message}")),
          );
        },
        codeSent: (String verificationId, int? resendToken) {
          _showOTPDialog(verificationId);
        },
        codeAutoRetrievalTimeout: (String verificationId) {},
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _appStrings!.get("invalid_mobile_number"),
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  // Displays a dialog for OTP input and verification.
  void _showOTPDialog(String verificationId) {
    if (_appStrings == null) return; // Ensure strings are loaded

    List<TextEditingController> controllers =
        List.generate(6, (_) => TextEditingController());

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: Text(_appStrings!.get("enter_otp")),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(6, (index) {
                  return SizedBox(
                    width: 40,
                    child: TextField(
                      controller: controllers[index],
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      maxLength: 1,
                      decoration: const InputDecoration(
                        counterText: "",
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        if (value.isNotEmpty && index < 5) {
                          FocusScope.of(context).nextFocus();
                        }
                      },
                    ),
                  );
                }),
              ),
              const SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: () async {
                    final smsCode = controllers.map((c) => c.text).join();
                    if (smsCode.length == 6) {
                      final credential = PhoneAuthProvider.credential(
                        verificationId: verificationId,
                        smsCode: smsCode,
                      );

                      try {
                        await FirebaseAuth.instance.signInWithCredential(credential);
                        Navigator.pop(context); // Close dialog
                        _goToWelcomeScreen();   // Go to next screen
                      } catch (e) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("${_appStrings!.get("otp_verification_failed")} ${e.toString()}"),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(_appStrings!.get("enter_all_otp_digits")),
                          backgroundColor: Colors.orange,
                        ),
                      );
                    }
                  },
                  child: Text(_appStrings!.get("verify")),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Navigates to the Welcome Screen after successful OTP login.
  void _goToWelcomeScreen() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
    );
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
          // Full background image with a dark overlay.
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

                            // Welcome text, now localized.
                            Text(
                              _appStrings!.get("welcome_to_app"),
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 40),

                            // Constrained input & button section.
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 400),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
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
                                  const SizedBox(height: 20),
                                  ElevatedButton(
                                    onPressed: _login,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green[800],
                                      minimumSize: const Size.fromHeight(48),
                                    ),
                                    child: Text(
                                      _appStrings!.get("send_otp_login"), // Localized button text
                                      style: const TextStyle(color: Colors.white),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),

                            // Hyperlink-style Register Link, now localized.
                            MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const RegistrationScreen(),
                                    ),
                                  );
                                },
                                child: Text(
                                  _appStrings!.get("new_user_register_here"), // Localized link text
                                  style: const TextStyle(
                                    color: Colors.lightBlueAccent,
                                    decoration: TextDecoration.underline,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
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
