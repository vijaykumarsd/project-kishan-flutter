import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:typed_data';

import 'shared_scaffold.dart';
import 'app_localizations.dart'; // Import AppLocalizations
import 'package:shared_preferences/shared_preferences.dart'; // Import for SharedPreferences

class ProfileUpdateScreen extends StatefulWidget {
  const ProfileUpdateScreen({super.key});

  @override
  State<ProfileUpdateScreen> createState() => _ProfileUpdateScreenState();
}

class _ProfileUpdateScreenState extends State<ProfileUpdateScreen> {
  int _currentIndex = 3; // Set to 3 to highlight the 'Profile' tab
  AppLocalizations? _appStrings; // Added AppLocalizations instance
  String _selectedLanguage = 'en'; // Track selected language

  @override
  void initState() {
    super.initState();
    _loadSelectedLanguage(); // Load language when the screen initializes
  }

  // Asynchronously loads the selected language from SharedPreferences.
  Future<void> _loadSelectedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedLanguage = prefs.getString('app_language') ?? 'en';
      print(_selectedLanguage);
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

  // Titles for the AppBar corresponding to each tab, now localized
  List<String> _getTitles() {
    if (_appStrings == null) {
      return const ['Loading...', 'Loading...', 'Loading...', 'Loading...'];
    }
    return [
      _appStrings!.get('dashboard'),
      _appStrings!.get('messages'),
      _appStrings!.get('alerts'),
      _appStrings!.get('update_profile'), // Localized title for profile screen
    ];
  }

  // This will manage the screen's body when using the bottom navigation
  List<Widget> _getScreens() {
    if (_appStrings == null) {
      return [
        const Center(child: CircularProgressIndicator()),
        const Center(child: CircularProgressIndicator()),
        const Center(child: CircularProgressIndicator()),
        const Center(child: CircularProgressIndicator()),
      ];
    }
    return [
      Center(child: Text(_appStrings!.get('dashboard') + ' ' + _appStrings!.get('profile'))), // Placeholder localized
      Center(child: Text(_appStrings!.get('messages') + ' ' + _appStrings!.get('profile'))),  // Placeholder localized
      Center(child: Text(_appStrings!.get('alerts') + ' ' + _appStrings!.get('profile'))),    // Placeholder localized
      ProfileUpdateForm(appStrings: _appStrings!), // Pass appStrings to ProfileUpdateForm
    ];
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_appStrings == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // The SharedScaffold now provides the AppBar, Drawer, and BottomNavigationBar
    return SharedScaffold(
      title: _getTitles()[_currentIndex],
      currentIndex: _currentIndex,
      onTabTapped: _onTabTapped,
      body: _getScreens()[_currentIndex],
    );
  }
}


// The original content of the screen is now extracted into its own widget
class ProfileUpdateForm extends StatefulWidget {
  final AppLocalizations appStrings; // Receive AppLocalizations

  const ProfileUpdateForm({super.key, required this.appStrings});

  @override
  State<ProfileUpdateForm> createState() => _ProfileUpdateFormState();
}

class _ProfileUpdateFormState extends State<ProfileUpdateForm> {
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final mobileController = TextEditingController();
  final emailController = TextEditingController();
  final addressController = TextEditingController();
  final stateController = TextEditingController();
  final cityController = TextEditingController();
  final pincodeController = TextEditingController();
  String? selectedGender;
  DateTime? selectedDate;
  Uint8List? imageBytes;
  String? imageUrl;
  String? _loggedInPhoneNumber; // Added to store the retrieved phone number

  // Define the consistent, language-agnostic keys for gender
  final List<String> _genderKeys = ['male', 'female', 'other'];

  // This list will hold the localized display strings for gender
  late List<String> _localizedGenderOptions;

  @override
  void initState() {
    super.initState();
    _loadLocalizedGenderOptions(); // Initialize localized options first
    _loadProfileData();
  }

  @override
  void dispose() {
    // Dispose of all TextEditingControllers to prevent memory leaks
    firstNameController.dispose();
    lastNameController.dispose();
    mobileController.dispose();
    emailController.dispose();
    addressController.dispose();
    stateController.dispose();
    cityController.dispose();
    pincodeController.dispose();
    super.dispose();
  }

  // Load localized gender options based on current appStrings
  void _loadLocalizedGenderOptions() {
    _localizedGenderOptions = _genderKeys.map((key) => widget.appStrings.get(key)).toList();
  }

  Future<void> _loadProfileData() async {
    final prefs = await SharedPreferences.getInstance();
    _loggedInPhoneNumber = prefs.getString('logged_in_phone'); // Retrieve here
    print('DEBUG: _loggedInPhoneNumber from SharedPreferences: $_loggedInPhoneNumber');


    if (_loggedInPhoneNumber == null || _loggedInPhoneNumber!.isEmpty) {
      print("DEBUG: Logged in phone number is null or empty. Cannot fetch profile data.");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.appStrings.get("phone_number_not_found_for_profile")), // Localized
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('farmers')
          .doc(_loggedInPhoneNumber) // Use the retrieved phone number
          .get();

      print('DEBUG: Firestore query for document ID: $_loggedInPhoneNumber');
      print('DEBUG: Document exists: ${doc.exists}');

      if (doc.exists) {
        final data = doc.data()!;
        print('DEBUG: Document data: $data');
        if (mounted) {
          setState(() {
            firstNameController.text = data['first_name'] ?? '';
            lastNameController.text = data['last_name'] ?? '';
            mobileController.text = data['phone_number'] ?? '';
            emailController.text = data['email'] ?? '';
            addressController.text = data['address'] ?? '';
            stateController.text = data['state'] ?? '';
            cityController.text = data['city'] ?? '';
            pincodeController.text = data['pincode'] ?? '';

            // Retrieve the stored gender key (e.g., 'male', 'female')
            String? storedGenderKey = data['gender']?.toLowerCase();
            if (_genderKeys.contains(storedGenderKey)) {
              // If the stored key is valid, get its localized version for display
              selectedGender = widget.appStrings.get(storedGenderKey!);
            } else {
              selectedGender = null; // No valid gender stored or found
            }

            imageUrl = data['profile_image_url'];
            if (data['date_of_birth'] != null) {
              selectedDate = (data['date_of_birth'] as Timestamp).toDate();
            }
          });
          print('DEBUG: Profile data successfully loaded and set to controllers.');
        }
      } else {
        print('DEBUG: Document does not exist for phone number: $_loggedInPhoneNumber');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(widget.appStrings.get("profile_not_found")), // Localized
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      print("ERROR: Error loading profile data: $e");
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("${widget.appStrings.get("failed_to_load_profile")} ${e.toString()}"), // Localized
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      if (mounted) {
        setState(() {
          imageBytes = bytes; // Show local preview immediately
        });
      }
      await _uploadImageToFirebase(pickedFile);
    }
  }

  Future<void> _uploadImageToFirebase(XFile imageFile) async {
    if (_loggedInPhoneNumber == null) {
      print("Logged in phone number not available for image upload.");
      return;
    }

    try {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('profile_images/${_loggedInPhoneNumber}.jpg'); // Use the retrieved phone number
      
      await storageRef.putData(await imageFile.readAsBytes());
      final url = await storageRef.getDownloadURL();
      
      await FirebaseFirestore.instance
          .collection('farmers')
          .doc(_loggedInPhoneNumber) // Use the retrieved phone number
          .update({'profile_image_url': url});

      if (mounted) {
        setState(() {
          imageUrl = url;
        });
      }
    } catch (e) {
      print('Image upload error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("${widget.appStrings.get("image_upload_failed")} ${e.toString()}"), // Localized
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.green[800]!, // Dark green for header background
              onPrimary: Colors.white, // White text on header
              onSurface: Colors.black87, // Black text for dates
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Colors.green[800], // Dark green for buttons
                textStyle: const TextStyle(fontWeight: FontWeight.bold), // Bold sans-serif for button text
              ),
            ),
            // Removed the dialogTheme property as it was causing the type error
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  Future<void> _updateProfile() async {
    if (_loggedInPhoneNumber == null) {
      print("Logged in phone number not available for profile update.");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.appStrings.get("phone_number_not_available_for_update")), // Localized
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    try {
      final docRef = FirebaseFirestore.instance
          .collection('farmers')
          .doc(_loggedInPhoneNumber); // Use the retrieved phone number

      // Find the English key for the selected localized gender
      String? genderKeyToSave;
      if (selectedGender != null) {
        // Find the index of the selected localized gender
        int? selectedIndex;
        for (int i = 0; i < _localizedGenderOptions.length; i++) {
          if (_localizedGenderOptions[i] == selectedGender) {
            selectedIndex = i;
            break;
          }
        }
        // If found, use the corresponding English key
        if (selectedIndex != null) {
          genderKeyToSave = _genderKeys[selectedIndex];
        }
      }

      await docRef.set({ // Using .set with merge:true is safer
        'first_name': firstNameController.text.trim(),
        'last_name': lastNameController.text.trim(),
        'phone_number': mobileController.text.trim(),
        'email': emailController.text.trim(),
        'address': addressController.text.trim(),
        'state': stateController.text.trim(),
        'city': cityController.text.trim(),
        'pincode': pincodeController.text.trim(),
        'gender': genderKeyToSave, // Save the English key to Firestore
        'date_of_birth':
            selectedDate != null ? Timestamp.fromDate(selectedDate!) : null,
        'updated_at': Timestamp.now(),
      }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(widget.appStrings.get("profile_updated_successfully"), style: const TextStyle(color: Colors.white)), // Localized
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("${widget.appStrings.get("error_updating_profile")} ${e.toString()}"), // Localized
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  InputDecoration _inputDecoration(String labelText) {
    return InputDecoration(
      labelText: labelText,
      labelStyle: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.normal), // Regular sans-serif
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12), // Rounded corners
        borderSide: BorderSide.none, // No border line
      ),
      filled: true,
      fillColor: Colors.grey[100], // Light grey background
      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.green[100], // Light green background
            child: ClipOval(
              child: imageBytes != null
                  ? Image.memory(
                      imageBytes!,
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                    )
                  : imageUrl != null
                      ? Image.network(
                          imageUrl!,
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.green[800]!),
                            ));
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(Icons.person, size: 40, color: Colors.green[700]);
                          },
                        )
                      : Icon(Icons.person, size: 40, color: Colors.green[700]),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: Icon(Icons.camera_alt, color: Colors.green[700]),
                onPressed: () => _pickImage(ImageSource.camera),
                tooltip: widget.appStrings.get("take_a_picture"), // Localized
              ),
              IconButton(
                icon: Icon(Icons.photo_library, color: Colors.green[700]),
                onPressed: () => _pickImage(ImageSource.gallery),
                tooltip: widget.appStrings.get("choose_from_gallery"), // Localized
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: firstNameController,
            decoration: _inputDecoration(widget.appStrings.get("first_name")),
            style: const TextStyle(fontWeight: FontWeight.normal, color: Colors.black87),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: lastNameController,
            decoration: _inputDecoration(widget.appStrings.get("last_name")),
            style: const TextStyle(fontWeight: FontWeight.normal, color: Colors.black87),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: mobileController,
            decoration: _inputDecoration(widget.appStrings.get("mobile_number")).copyWith(enabled: false), // Localized and disabled for editing
            style: const TextStyle(fontWeight: FontWeight.normal, color: Colors.black54), // Dimmed text for disabled field
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: selectedGender,
            items: _localizedGenderOptions.map((gender) => DropdownMenuItem( // Use localized options
              value: gender,
              child: Text(gender),
            )).toList(),
            onChanged: (value) => setState(() => selectedGender = value),
            decoration: _inputDecoration(widget.appStrings.get("gender")), // Localized
            style: const TextStyle(fontWeight: FontWeight.normal, color: Colors.black87),
            iconEnabledColor: Colors.green[700],
          ),
          const SizedBox(height: 16),
          TextFormField(
            readOnly: true,
            onTap: _pickDate,
            controller: TextEditingController(
              text: selectedDate != null ? "${selectedDate!.toLocal()}".split(' ')[0] : ""
            ),
            decoration: _inputDecoration(widget.appStrings.get("date_of_birth")).copyWith(
              hintText: widget.appStrings.get("select_date"), // Localized
            ),
            style: const TextStyle(fontWeight: FontWeight.normal, color: Colors.black87),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: emailController,
            decoration: _inputDecoration(widget.appStrings.get("email")), // Localized
            style: const TextStyle(fontWeight: FontWeight.normal, color: Colors.black87),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: addressController,
            decoration: _inputDecoration(widget.appStrings.get("address")), // Localized
            style: const TextStyle(fontWeight: FontWeight.normal, color: Colors.black87),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: stateController,
            decoration: _inputDecoration(widget.appStrings.get("state")), // Localized
            style: const TextStyle(fontWeight: FontWeight.normal, color: Colors.black87),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: cityController,
            decoration: _inputDecoration(widget.appStrings.get("city")), // Localized
            style: const TextStyle(fontWeight: FontWeight.normal, color: Colors.black87),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: pincodeController,
            decoration: _inputDecoration(widget.appStrings.get("pincode")), // Localized
            style: const TextStyle(fontWeight: FontWeight.normal, color: Colors.black87),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _updateProfile,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[800], // Dark green button
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(50), // Consistent button height
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12), // Rounded corners
              ),
              elevation: 4, // Subtle shadow
              textStyle: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold, // Bold sans-serif for button text
              ),
            ),
            child: Text(widget.appStrings.get("update_profile")), // Localized
          ),
        ],
      ),
    );
  }
}
