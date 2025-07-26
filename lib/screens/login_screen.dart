import 'package:flutter/material.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'registration_screen.dart';
import 'welcome_screen.dart';
import 'app_localizations.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  String _fullPhoneNumber = '';
  String _selectedLanguage = 'en';
  AppLocalizations? _appStrings;

  @override
  void initState() {
    super.initState();
    _loadSelectedLanguage();
  }

  Future<void> _loadSelectedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedLanguage = prefs.getString('app_language') ?? 'en';
    });
    await _loadAppStrings(_selectedLanguage);
  }

  Future<void> _loadAppStrings(String locale) async {
    final loadedStrings = await AppLocalizations.load(locale);
    setState(() {
      _appStrings = loadedStrings;
    });
  }

  void _login() async {
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
            content: Text(_appStrings!.get("mobile_number_not_found")),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }

      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: _fullPhoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
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
                content: Text("${_appStrings!.get("verification_failed")} ${e.message}"),
                backgroundColor: Colors.redAccent,
              ),
            );
          }
        },
        codeSent: (String verificationId, int? resendToken) {
          _showOtpDialog(verificationId);
        },
        codeAutoRetrievalTimeout: (String verificationId) {},
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_appStrings!.get("invalid_mobile_number")),
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
          title: Text(
            _appStrings!.get("enter_otp"),
            style: const TextStyle(
              fontWeight: FontWeight.bold, // Bold for heading
              color: Colors.black87, // Dark color for heading
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  smsCode = value;
                },
                decoration: InputDecoration(
                  labelText: _appStrings!.get("enter_otp"),
                  border: OutlineInputBorder(
                     borderRadius: BorderRadius.circular(10), // Rounded corners
                  ),
                  filled: true,
                  fillColor: Colors.grey[100], // Light grey fill
                ),
                style: const TextStyle(
                  fontWeight: FontWeight.normal, // Regular sans-serif
                  color: Colors.black87,
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
                        Navigator.of(context).pop();
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                        );
                      }
                    } on FirebaseAuthException catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("${_appStrings!.get("otp_verification_failed")} ${e.message}"),
                            backgroundColor: Colors.redAccent,
                          ),
                        );
                      }
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(_appStrings!.get("enter_all_otp_digits")),
                        backgroundColor: Colors.orangeAccent,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[800], // Dark green button
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12), // Rounded corners
                  ),
                  elevation: 4, // Subtle shadow
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold, // Bold sans-serif
                  ),
                ),
                child: Text(_appStrings!.get("verify")),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_appStrings == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background Image (assuming farmer.jpg exists in assets/images)
          Image.asset(
            'assets/images/farmer.jpg',
            fit: BoxFit.cover,
          ),
          Container(
            color: Colors.black.withOpacity(0.4), // Dark overlay
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Circular Logo (assuming kisan_image.png exists in assets/images)
                      ClipOval(
                        child: Image.asset(
                          'assets/images/kisan_image.png',
                          height: 100,
                          width: 100,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Welcome text
                      Text(
                        _appStrings!.get("welcome_to_app"),
                        style: const TextStyle(
                          fontSize: 28, // Larger font size
                          fontWeight: FontWeight.bold, // Bold sans-serif for heading
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 30),

                      // Phone Number Field
                      IntlPhoneField(
                        decoration: InputDecoration(
                          labelText: _appStrings!.get("mobile_number"),
                          border: OutlineInputBorder( // Apply rounded corners to input field
                            borderRadius: BorderRadius.circular(12), // More rounded corners
                          ),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.9), // White background for input with slight opacity
                          labelStyle: TextStyle(color: Colors.grey[700]),
                          hintStyle: TextStyle(color: Colors.grey[500]),
                        ),
                        initialCountryCode: 'IN',
                        onChanged: (phone) {
                          _fullPhoneNumber = phone.completeNumber;
                        },
                        style: const TextStyle(
                          color: Colors.black87, // Regular sans-serif for input text
                          fontWeight: FontWeight.normal,
                        ),
                        dropdownTextStyle: const TextStyle(
                          color: Colors.black87, // Regular sans-serif for dropdown
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Login Button
                      ElevatedButton(
                        onPressed: _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[800], // Dark green button
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12), // Rounded corners
                          ),
                          elevation: 4, // Subtle shadow
                          textStyle: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold, // Bold sans-serif for button text
                          ),
                        ),
                        child: Text(_appStrings!.get("send_otp_login")),
                      ),
                      const SizedBox(height: 10),

                      // Register link
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
                            _appStrings!.get("new_user_register_here"),
                            style: const TextStyle(
                              color: Colors.white70, // Slightly desaturated for better contrast on dark overlay
                              decoration: TextDecoration.underline,
                              fontWeight: FontWeight.normal, // Regular sans-serif for body text
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
        ],
      ),
    );
  }
}
