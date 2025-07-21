import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:typed_data';

import 'shared_scaffold.dart'; // Import the shared scaffold

class ProfileUpdateScreen extends StatefulWidget {
  // Hardcoded phone number for demonstration
  final String phoneNumber = "+919566859696";
  const ProfileUpdateScreen({super.key});

  @override
  State<ProfileUpdateScreen> createState() => _ProfileUpdateScreenState();
}

class _ProfileUpdateScreenState extends State<ProfileUpdateScreen> {
  int _currentIndex = 3; // Set to 3 to highlight the 'Profile' tab

  // This will manage the screen's body when using the bottom navigation
  // Note: This architecture places the main navigation on every screen as requested.
  final List<Widget> _screens = [
    const Center(child: Text('Dashboard Screen')), // Placeholder
    const Center(child: Text('Messages Screen')),  // Placeholder
    const Center(child: Text('Alerts Screen')),    // Placeholder
    const ProfileUpdateForm(), // The actual profile form content
  ];

  final List<String> _titles = const [
    'Dashboard',
    'Messages',
    'Alerts',
        'Update Profile', // Title for the profile screen
  ];

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
    // In a real app, you might navigate here instead of just changing the body
  }
  
  @override
  Widget build(BuildContext context) {
    // The SharedScaffold now provides the AppBar, Drawer, and BottomNavigationBar
    return SharedScaffold(
      title: _titles[_currentIndex],
      currentIndex: _currentIndex,
      onTabTapped: _onTabTapped,
      body: _screens[_currentIndex],
    );
  }
}


// The original content of the screen is now extracted into its own widget
class ProfileUpdateForm extends StatefulWidget {
  final String phoneNumber = "+919566859696"; // You may need to pass this in
  const ProfileUpdateForm({super.key});

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

  final List<String> genderOptions = ['Male', 'Female', 'Other'];

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('farmers')
          .doc(widget.phoneNumber)
          .get();
      if (doc.exists) {
        final data = doc.data()!;
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
            selectedGender = data['gender'];
            imageUrl = data['profile_image_url'];
            if (data['date_of_birth'] != null) {
              selectedDate = (data['date_of_birth'] as Timestamp).toDate();
            }
          });
        }
      }
    } catch (e) {
      print("Error loading profile data: $e");
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to load profile data: ${e.toString()}"),
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
    try {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('profile_images/${widget.phoneNumber}.jpg');
      
      await storageRef.putData(await imageFile.readAsBytes());
      final url = await storageRef.getDownloadURL();
      
      await FirebaseFirestore.instance
          .collection('farmers')
          .doc(widget.phoneNumber)
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
            content: Text("Image upload failed: ${e.toString()}"),
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
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  Future<void> _updateProfile() async {
    try {
      final docRef = FirebaseFirestore.instance
          .collection('farmers')
          .doc(widget.phoneNumber);
      await docRef.set({ // Using .set with merge:true is safer
        'first_name': firstNameController.text.trim(),
        'last_name': lastNameController.text.trim(),
        'phone_number': mobileController.text.trim(),
        'email': emailController.text.trim(),
        'address': addressController.text.trim(),
        'state': stateController.text.trim(),
        'city': cityController.text.trim(),
        'pincode': pincodeController.text.trim(),
        'gender': selectedGender,
        'date_of_birth':
            selectedDate != null ? Timestamp.fromDate(selectedDate!) : null,
        'updated_at': Timestamp.now(),
      }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text("Profile Updated Successfully!", style: TextStyle(color: Colors.white)),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error updating profile: ${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // This is the original body of your screen
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.grey[200],
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
                            return const Center(child: CircularProgressIndicator());
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(Icons.person, size: 40);
                          },
                        )
                      : const Icon(Icons.person, size: 40),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.camera_alt),
                onPressed: () => _pickImage(ImageSource.camera),
                tooltip: "Take a picture",
              ),
              IconButton(
                icon: const Icon(Icons.photo_library),
                onPressed: () => _pickImage(ImageSource.gallery),
                tooltip: "Choose from gallery",
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(controller: firstNameController, decoration: const InputDecoration(labelText: "First Name")),
          const SizedBox(height: 16),
          TextField(controller: lastNameController, decoration: const InputDecoration(labelText: "Last Name")),
          const SizedBox(height: 16),
          TextField(controller: mobileController, decoration: const InputDecoration(labelText: "Mobile Number")),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: selectedGender,
            items: genderOptions.map((gender) => DropdownMenuItem(
              value: gender,
              child: Text(gender),
            )).toList(),
            onChanged: (value) => setState(() => selectedGender = value),
            decoration: const InputDecoration(labelText: "Gender"),
          ),
          const SizedBox(height: 16),
          TextFormField(
            readOnly: true,
            onTap: _pickDate,
            controller: TextEditingController(
              text: selectedDate != null ? "${selectedDate!.toLocal()}".split(' ')[0] : ""
            ),
            decoration: const InputDecoration(
              labelText: "Date of Birth",
              hintText: "Select Date",
            ),
          ),
          const SizedBox(height: 16),
          TextField(controller: emailController, decoration: const InputDecoration(labelText: "Email")),
          const SizedBox(height: 16),
          TextField(controller: addressController, decoration: const InputDecoration(labelText: "Address")),
          const SizedBox(height: 16),
          TextField(controller: stateController, decoration: const InputDecoration(labelText: "State")),
          const SizedBox(height: 16),
          TextField(controller: cityController, decoration: const InputDecoration(labelText: "City")),
          const SizedBox(height: 16),
          TextField(controller: pincodeController, decoration: const InputDecoration(labelText: "Pincode")),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _updateProfile,
            child: const Text("Update Profile"),
          ),
        ],
      ),
    );
  }
}