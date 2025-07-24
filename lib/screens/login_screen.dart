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
  String _selectedLanguage = 'en'; // Default language, will be loaded from prefs
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

  void _login() async {
    // Ensure appStrings are loaded before proceeding
    if (_appStrings == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please wait, loading app data..."),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }

    if (_fullPhoneNumber.isNotEmpty && _fullPhoneNumber.length > 8) {
      final snapshot = await FirebaseFirestore.instance
          .collection('farmers')
          .doc(_fullPhoneNumber)
          .get();

      if (!snapshot.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_appStrings!.get("mobile_number_not_found")), // Localized message
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
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const WelcomeScreen()),
            );
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("${_appStrings!.get("verification_failed")} ${e.message}"), // Localized message
                backgroundColor: Colors.redAccent,
              ),
            );
          }
        },
        codeSent: (String verificationId, int? resendToken) {
          // Navigate to OTP screen or show OTP input
          _showOtpDialog(verificationId);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          // Called when OTP auto-retrieval times out
        },
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_appStrings!.get("invalid_mobile_number")), // Localized message
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _showOtpDialog(String verificationId) {
    String smsCode = '';
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(_appStrings!.get("enter_otp")), // Localized title
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  smsCode = value;
                },
                decoration: InputDecoration(
                  labelText: _appStrings!.get("enter_otp"), // Localized label
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  if (smsCode.length == 6) {
                    PhoneAuthCredential credential = PhoneAuthProvider.credential(
                      verificationId: verificationId,
                      smsCode: smsCode,
                    );
                    try {
                      await FirebaseAuth.instance.signInWithCredential(credential);
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setString('logged_in_phone', _fullPhoneNumber);
                      if (mounted) {
                        Navigator.of(context).pop(); // Close dialog
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                        );
                      }
                    } on FirebaseAuthException catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("${_appStrings!.get("otp_verification_failed")} ${e.message}"), // Localized message
                            backgroundColor: Colors.redAccent,
                          ),
                        );
                      }
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(_appStrings!.get("enter_all_otp_digits")), // Localized message
                        backgroundColor: Colors.orangeAccent,
                      ),
                    );
                  }
                },
                child: Text(_appStrings!.get("verify")), // Localized button text
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Show a loading indicator if appStrings are not yet loaded
    if (_appStrings == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white, // Changed to plain white background
      body: Center( // Center the content
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App Logo/Icon (removed background image and gradient)
              Image.asset(
                'assets/images/kisan_image.png', // Assuming you have a default app logo here
                height: 120,
              ),
              const SizedBox(height: 30),

              // Welcome text
              Text(
                _appStrings!.get("welcome_to_app"), // Localized
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87, // Changed text color for white background
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),

              // Phone Number Input
              IntlPhoneField(
                decoration: InputDecoration(
                  labelText: _appStrings!.get("mobile_number"), // Localized
                  border: const OutlineInputBorder(
                    borderSide: BorderSide(),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade200, // Lighter fill color for white background
                ),
                initialCountryCode: 'IN', // Assuming India as default
                onChanged: (phone) {
                  _fullPhoneNumber = phone.completeNumber;
                },
                style: const TextStyle(color: Colors.black),
                dropdownTextStyle: const TextStyle(color: Colors.black),
              ),
              const SizedBox(height: 20),

              // Login Button
              ElevatedButton(
                onPressed: _login,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[700],
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                child: Text(_appStrings!.get("send_otp_login")), // Localized
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
    );
  }
}
