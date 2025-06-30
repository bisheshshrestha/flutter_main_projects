import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:recycle_mate/services/shared_pref.dart';
import 'package:recycle_mate/services/widget_support.dart';

class UploadProfilePage extends StatefulWidget {
  final String userId;
  final String? googlePhotoUrl; // Pass this if available

  const UploadProfilePage({
    Key? key,
    required this.userId,
    this.googlePhotoUrl,
  }) : super(key: key);

  @override
  State<UploadProfilePage> createState() => _UploadProfilePageState();
}

class _UploadProfilePageState extends State<UploadProfilePage> {
  final TextEditingController _nameController = TextEditingController();
  File? _selectedImage;
  String? _imageUrl; // Google photo URL or local file path
  bool _isLoading = false;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _imageUrl = widget.googlePhotoUrl;
    _loadSavedName();
  }

  Future<void> _loadSavedName() async {
    final savedName = await SharedPreferenceHelper().getUserName();
    if (savedName != null && savedName.isNotEmpty) {
      setState(() {
        _nameController.text = savedName;
      });
    }
  }


  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _selectedImage = File(picked.path);
        _imageUrl = picked.path; // Use local path for display and storage
      });
    }
  }

  Future<void> _uploadProfile() async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter your name.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Save to Firestore
      await FirebaseFirestore.instance.collection('users').doc(widget.userId).set({
        'name': _nameController.text.trim(),
        'image': _imageUrl ?? "", // Google photo URL or local path
      }, SetOptions(merge: true));

      // Save locally using SharedPreferenceHelper
      await SharedPreferenceHelper().saveUserName(_nameController.text.trim());
      await SharedPreferenceHelper().saveUserImage(_imageUrl ?? "");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Profile uploaded successfully!')),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload profile: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildProfileImage() {
    if (_selectedImage != null) {
      // If user picked a new image, show it
      return CircleAvatar(
        radius: 60,
        backgroundImage: FileImage(_selectedImage!),
      );
    } else if (_imageUrl != null && _imageUrl!.isNotEmpty) {
      // If Google photo URL is available, show it
      if (_imageUrl!.startsWith("http")) {
        return CircleAvatar(
          radius: 60,
          backgroundImage: NetworkImage(_imageUrl!),
        );
      } else {
        // Local file path
        return CircleAvatar(
          radius: 60,
          backgroundImage: FileImage(File(_imageUrl!)),
        );
      }
    } else {
      // Default avatar
      return CircleAvatar(
        radius: 60,
        backgroundColor: Colors.grey[300],
        child: Icon(Icons.camera_alt, size: 40, color: Colors.grey[700]),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar with back arrow and centered title
            Padding(
              padding: const EdgeInsets.only(left: 20.0, right: 20.0, top: 20.0),
              child: Row(
                children: [
                  // Back arrow button
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: Material(
                      elevation: 3.0,
                      borderRadius: BorderRadius.circular(60),
                      child: Container(
                        padding: EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(60),
                        ),
                        child: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Color(0xFFececf8),
                          size: 30.0,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        "Upload Profile",
                        style: AppWidget.headlineTextStyle(25.0),
                      ),
                    ),
                  ),
                  // To keep the title centered, add a transparent icon of same size
                  Opacity(
                    opacity: 0,
                    child: Material(
                      elevation: 3.0,
                      borderRadius: BorderRadius.circular(60),
                      child: Container(
                        padding: EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(60),
                        ),
                        child: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Color(0xFFececf8),
                          size: 30.0,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 30),
            // Profile image picker
            GestureDetector(
              onTap: _pickImage,
              child: _buildProfileImage(),
            ),
            SizedBox(height: 30),
            // Name field
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: "Enter your name",
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            SizedBox(height: 40),
            // Upload Profile Button (styled like Points redeem button)
            _isLoading
                ? CircularProgressIndicator()
                : GestureDetector(
              onTap: _uploadProfile,
              child: Center(
                child: Material(
                  elevation: 2.0,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    height: 50.0,
                    width: MediaQuery.of(context).size.width / 1.5,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Center(
                      child: Text(
                        "Upload Profile",
                        style: AppWidget.whiteTextStyle(22.0),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}