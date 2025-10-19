// lib/screens/profile_screen.dart (Updated with Editable Feed Subscriptions)

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb; 
import 'package:image_picker/image_picker.dart'; 
import 'dart:io'; 
import '../services/auth_service.dart';
import '../models/user_model.dart';
import '../config/api_config.dart';

class ProfileScreen extends StatefulWidget {
  final Future<UserProfile> userDataFuture;

  const ProfileScreen({
    super.key,
    required this.userDataFuture,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Controllers for editable text fields
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _collegeController = TextEditingController();
  final TextEditingController _departmentController = TextEditingController();
  final TextEditingController _courseController = TextEditingController();
  final TextEditingController _yearController = TextEditingController();

  UserProfile? _currentProfile;
  XFile? _pickedImage;
  bool _isLoading = false;
  
  // --- NEW: State for Feed Types ---
  Set<String> _selectedFeedTypes = {}; 
  
  // Define available feed types (replace with your actual API list if needed)
  final List<String> _availableFeedTypes = [
    'Technology',
    'Science',
    'Arts',
    'Sports',
    'News',
    'Research',
    'Projects',
    'Events',
    'Campus',
    'FRONTEND'
  ];
  // --- END NEW ---

  @override
  void initState() {
    super.initState();
    _populateControllers();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _collegeController.dispose();
    _departmentController.dispose();
    _courseController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  void _populateControllers() async {
    try {
      final data = await widget.userDataFuture;
      
      setState(() {
        _currentProfile = data; 
        _firstNameController.text = data.firstName ?? '';
        _lastNameController.text = data.lastName ?? '';
        _collegeController.text = data.collegeUniversity ?? '';
        _departmentController.text = data.department ?? '';
        _courseController.text = data.course ?? '';
        _yearController.text = data.currentYear?.toString() ?? '';
        
        // --- NEW: Initialize selected feed types from user profile ---
        _selectedFeedTypes = data.feedTypes.toSet();
        // --- END NEW ---
      });
    } catch (e) {
      print('Error populating controllers: $e');
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load profile data: $e')),
        );
      }
    }
  }

  // Handles picking an image (returns XFile which is platform-agnostic)
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 50);

    if (image != null) {
      setState(() {
        _pickedImage = image; // Store the XFile object
      });
    }
  }
  
  // Handles the image upload using the unified patchProfile
  Future<void> _handleImageUpload() async {
    if (_pickedImage == null || _currentProfile == null) return;
    
    setState(() => _isLoading = true);
    
    // Create a temporary profile object containing existing data
    final tempProfile = UserProfile(
      username: _currentProfile!.username,
      email: _currentProfile!.email,
      isActive: _currentProfile!.isActive,
      firstName: _currentProfile!.firstName,
      lastName: _currentProfile!.lastName,
      collegeUniversity: _currentProfile!.collegeUniversity,
      department: _currentProfile!.department,
      course: _currentProfile!.course,
      currentYear: _currentProfile!.currentYear,
      profileImage: _currentProfile!.profileImage,
      feedTypes: _currentProfile!.feedTypes, // Use current list
    );

    try {
      // Call patchProfile with ONLY the imageXFile
      final updatedProfile = await _authService.patchProfile(
        updatedProfile: tempProfile,
        imageXFile: _pickedImage, 
      );
      
      // Update the current profile and reset the picked image
      setState(() {
        _currentProfile = updatedProfile;
        _pickedImage = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile picture updated successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Image upload failed: ${e.toString().replaceFirst('Exception: ', '')}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Handles the profile text data update
  Future<void> _handleUpdateProfile() async {
    if (!_formKey.currentState!.validate() || _currentProfile == null) return;
    
    setState(() => _isLoading = true);

    // 1. Create a new UserProfile instance with updated text values AND feed types
    final updatedProfile = UserProfile(
      // Keep existing non-editable fields
      username: _currentProfile!.username,
      email: _currentProfile!.email,
      isActive: _currentProfile!.isActive,
      profileImage: _currentProfile!.profileImage, 
      
      // --- NEW: Update with the current selected feed types ---
      feedTypes: _selectedFeedTypes.toList(),
      // --- END NEW ---
      
      // Update with the current controller values
      firstName: _firstNameController.text.trim().isEmpty ? null : _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim().isEmpty ? null : _lastNameController.text.trim(),
      collegeUniversity: _collegeController.text.trim().isEmpty ? null : _collegeController.text.trim(),
      department: _departmentController.text.trim().isEmpty ? null : _departmentController.text.trim(),
      course: _courseController.text.trim().isEmpty ? null : _courseController.text.trim(),
      currentYear: int.tryParse(_yearController.text.trim()),
    );
    
    try {
      // 2. Call patchProfile with text data and feed types (imageXFile is null)
      final newProfile = await _authService.patchProfile(
        updatedProfile: updatedProfile,
        imageXFile: null,
      );

      // Update the current profile and selected feed types with the response data
      setState(() {
        _currentProfile = newProfile;
        _selectedFeedTypes = newProfile.feedTypes.toSet(); // Re-sync selected set
      });
      
      // Pop the screen to trigger HomeScreen refresh
      if (mounted) Navigator.pop(context); 

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile details updated successfully!')),
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Details update failed: ${e.toString().replaceFirst('Exception: ', '')}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // --- NEW: Widget to display and manage feed type selection ---
  Widget _buildFeedTypeSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select content types you want to see in your feed:', 
          style: TextStyle(fontSize: 14, color: Colors.grey)
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8.0,
          runSpacing: 4.0,
          children: _availableFeedTypes.map((feedType) {
            final isSelected = _selectedFeedTypes.contains(feedType);
            return FilterChip(
              label: Text(feedType),
              selected: isSelected,
              onSelected: (bool selected) {
                setState(() {
                  if (selected) {
                    _selectedFeedTypes.add(feedType);
                  } else {
                    _selectedFeedTypes.remove(feedType);
                  }
                });
              },
              selectedColor: Colors.teal.shade100,
              checkmarkColor: Colors.teal.shade900,
              labelStyle: TextStyle(
                color: isSelected ? Colors.teal.shade900 : Colors.black87,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              backgroundColor: Colors.grey.shade100,
            );
          }).toList(),
        ),
      ],
    );
  }
  // --- END NEW WIDGET ---

  Widget _buildReadOnlyField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        initialValue: value,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.grey[100],
        ),
        readOnly: true,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildEditableField(String label, TextEditingController controller, {TextInputType keyboardType = TextInputType.text, String? Function(String?)? validator}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
        ),
        validator: validator,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Profile'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<UserProfile>(
        future: widget.userDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting || _currentProfile == null) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error loading profile: ${snapshot.error}'));
          } else if (snapshot.hasData || _currentProfile != null) {
            final profile = _currentProfile!;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- Profile Image Section (Unchanged) ---
                    Center(
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 60,
                            backgroundColor: Colors.grey.shade200,
                            backgroundImage: (() {
                              if (_pickedImage != null) {
                                if (kIsWeb) {
                                  return NetworkImage(_pickedImage!.path);
                                } else {
                                  return FileImage(File(_pickedImage!.path));
                                }
                              }
                              if (profile.profileImage != null && profile.profileImage!.isNotEmpty) {
                                return NetworkImage('${ApiConfig.BASE_MEDIA_URL}${profile.profileImage}');
                              }
                              return null; 
                            })() as ImageProvider?,
                            child: _pickedImage == null && (profile.profileImage == null || profile.profileImage!.isEmpty)
                                ? Icon(Icons.person, size: 60, color: Colors.grey.shade700)
                                : null,
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ElevatedButton.icon(
                                onPressed: _isLoading ? null : _pickImage,
                                icon: const Icon(Icons.image),
                                label: const Text('Pick Image'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.teal.shade50,
                                  foregroundColor: Colors.teal,
                                ),
                              ),
                              if (_pickedImage != null) ...[
                                const SizedBox(width: 10),
                                ElevatedButton.icon(
                                  onPressed: _isLoading ? null : _handleImageUpload,
                                  icon: _isLoading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.upload),
                                  label: Text(_isLoading ? 'Uploading...' : 'Upload Image'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green.shade50,
                                    foregroundColor: Colors.green,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),

                    // --- Non-Editable Fields (Unchanged) ---
                    const Text('Account Credentials (Read-Only)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const Divider(height: 10),
                    _buildReadOnlyField('Username', profile.username),
                    _buildReadOnlyField('Email', profile.email),

                    const SizedBox(height: 20),

                    // --- Editable Fields (Unchanged) ---
                    const Text('General Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const Divider(height: 10),
                    _buildEditableField('First Name', _firstNameController),
                    _buildEditableField('Last Name', _lastNameController),

                    const SizedBox(height: 20),
                    const Text('Educational Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const Divider(height: 10),
                    _buildEditableField('College/University', _collegeController),
                    _buildEditableField('Department', _departmentController),
                    _buildEditableField('Course', _courseController),
                    _buildEditableField(
                      'Current Year (Number)',
                      _yearController,
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value != null && value.isNotEmpty && int.tryParse(value) == null) {
                          return 'Please enter a valid number for the year.';
                        }
                        return null;
                      }
                    ),

                    const SizedBox(height: 20),
                    
                    // --- UPDATED: Editable Feed Types Section ---
                    const Text('Feed Subscriptions (Select all that apply)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const Divider(height: 10),
                    _buildFeedTypeSelection(), // <-- NEW WIDGET
                    // --- END UPDATED ---

                    const SizedBox(height: 30),

                    // --- Submit Button for Text Fields ---
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleUpdateProfile,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          backgroundColor: Colors.indigo,
                          foregroundColor: Colors.white,
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                            : const Text('Update Profile Details', style: TextStyle(fontSize: 18)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          } else {
            return const Center(child: Text('No profile data available.'));
          }
        },
      ),
    );
  }
}