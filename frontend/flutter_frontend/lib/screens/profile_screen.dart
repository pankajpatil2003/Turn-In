import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb; 
import 'package:image_picker/image_picker.dart'; 
import 'dart:io'; 
import 'dart:async'; 

import '../services/auth_service.dart';
import '../models/user_model.dart';
import '../models/content_model.dart'; // <--- Assume TagInfo is defined here
import '../config/api_config.dart';

// Assuming UserProfile, TagInfo, and AuthService are defined elsewhere and correctly imported.

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
  final TextEditingController _feed_typesearchController = TextEditingController();

  UserProfile? _currentProfile;
  XFile? _pickedImage;
  bool _isLoading = false;
  
  // --- State for Dynamic Feed Types ---
  Set<String> _selectedFeedTypes = {}; 
  Future<List<TagInfo>>? _feed_typesFuture; // Future for fetched feed_types
  String _currentSort = 'rank'; // Default sort method
  Timer? _debounce; // For search debouncing
  // --- END State ---

  @override
  void initState() {
    super.initState();
    _populateControllers();
    // Setup listener for search input (debouncing)
    _feed_typesearchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _collegeController.dispose();
    _departmentController.dispose();
    _courseController.dispose();
    _yearController.dispose();
    _feed_typesearchController.dispose();
    _debounce?.cancel(); // Cancel debounce timer
    super.dispose();
  }
  
  // --- Debounce logic for search ---
  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      // Re-fetch tags only if the widget is still mounted
      if(mounted) {
        _fetchfeed_types(search: _feed_typesearchController.text);
      }
    });
  }
  
  // --- Fetch feed_types function ---
  void _fetchfeed_types({String? search}) {
    // Only fetch if a profile is loaded (assumed prerequisite for token availability)
    if (_currentProfile == null && search == null) {
      return; 
    }
    setState(() {
      _feed_typesFuture = _authService.fetchAvailablefeed_types(
        search: search,
        sort: _currentSort,
      );
    });
  }
  // --- END Fetch feed_types ---

  /// Populates controllers and initial state from the widget's Future.
  void _populateControllers() async {
    try {
      final data = await widget.userDataFuture;
      
      if (!mounted) return;

      setState(() {
        _currentProfile = data; 
        _firstNameController.text = data.firstName ?? '';
        _lastNameController.text = data.lastName ?? '';
        _collegeController.text = data.collegeUniversity ?? '';
        _departmentController.text = data.department ?? '';
        _courseController.text = data.course ?? '';
        _yearController.text = data.currentYear?.toString() ?? '';
        
        // 🔥 FIX: Use null-aware operator (?? []) to handle nullable feedTypes
        _selectedFeedTypes = (data.feedTypes ?? []).toSet();
      });
      
      // Now that the profile is loaded, trigger the initial tag fetch.
      _fetchfeed_types();
      
    } catch (e) {
      print('Error populating controllers: $e');
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load profile data: $e')),
        );
      }
    }
  }

  /// Handles picking an image.
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 50);

    if (image != null) {
      setState(() {
        _pickedImage = image; 
      });
    }
  }
  
  /// Handles the profile image upload.
  Future<void> _handleImageUpload() async {
    if (_pickedImage == null || _currentProfile == null) return;
    
    setState(() => _isLoading = true);
    
    // Create a temporary profile object containing only essential non-editable data 
    // and the *new* image file for the multipart request.
    // CRITICAL: All patchable fields are set to null to avoid validation conflicts (like feedTypes).
    final tempProfile = UserProfile(
      // Keep essential identity fields
      username: _currentProfile!.username,
      email: _currentProfile!.email,
      isActive: _currentProfile!.isActive,
      
      // Set all patchable fields to null to omit them from the JSON body
      firstName: null,
      lastName: null,
      collegeUniversity: null,
      department: null,
      course: null,
      currentYear: null,
      profileImage: null, // Always null for file uploads via multipart
      feedTypes: null, // <-- CRITICAL FIX: Ensures feed_types is not sent for validation
    );

    try {
      final updatedProfile = await _authService.patchProfile(
        updatedProfile: tempProfile,
        imageXFile: _pickedImage, 
      );
      
      if (!mounted) return;

      setState(() {
        _currentProfile = updatedProfile;
        _pickedImage = null; // Clear the picked image after successful upload
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile picture updated successfully!')),
      );
    } catch (e) {
      if (!mounted) return;
      final errorMessage = e.toString().replaceFirst('Exception: ', '').replaceFirst('Profile update failed! Response Body: ', '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Image upload failed! $errorMessage')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Handles the profile text data and feed types update.
  Future<void> _handleUpdateProfile() async {
    if (!_formKey.currentState!.validate() || _currentProfile == null) return;
    
    setState(() => _isLoading = true);

    // Create a new UserProfile instance with all updated values
    final updatedProfile = UserProfile(
      // Keep existing non-editable fields
      username: _currentProfile!.username,
      email: _currentProfile!.email,
      isActive: _currentProfile!.isActive,
      
      // CRITICAL: Set profileImage to null. This prevents sending the existing image URL 
      // in the JSON body, which would conflict with the server expecting a file.
      profileImage: null, 
      
      // Update with the current selected feed types 
      feedTypes: _selectedFeedTypes.toList(), // ⬅️ This is now List<String>? but _selectedFeedTypes is Set<String>
      
      // Update with the current controller values, using null for empty strings 
      // to only patch non-empty values.
      firstName: _firstNameController.text.trim().isEmpty ? null : _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim().isEmpty ? null : _lastNameController.text.trim(),
      collegeUniversity: _collegeController.text.trim().isEmpty ? null : _collegeController.text.trim(),
      department: _departmentController.text.trim().isEmpty ? null : _departmentController.text.trim(),
      course: _courseController.text.trim().isEmpty ? null : _courseController.text.trim(),
      currentYear: int.tryParse(_yearController.text.trim()),
    );
    
    try {
      // Pass imageXFile as null because this is a text/feedTypes update
      final newProfile = await _authService.patchProfile(
        updatedProfile: updatedProfile,
        imageXFile: null,
      );

      if (!mounted) return;

      // Update the current profile and selected feed types with the response data
      setState(() {
        _currentProfile = newProfile;
        // 🔥 FIX: Use null-aware operator (?? []) here too
        _selectedFeedTypes = (newProfile.feedTypes ?? []).toSet(); // Re-sync selected set
      });
      
      // Pop the screen to trigger HomeScreen refresh (if applicable)
      // Navigator.pop(context); 

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile details updated successfully!')),
      );

    } catch (e) {
      if (!mounted) return;
      final errorMessage = e.toString().replaceFirst('Exception: ', '').replaceFirst('Profile update failed! Response Body: ', '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Details update failed: $errorMessage')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Builds the profile image, pick, and upload buttons.
  Widget _buildProfileImageSection() {
    final profile = _currentProfile!;
    final Color primaryColor = Theme.of(context).colorScheme.primary;

    // Helper to get the correct ImageProvider based on platform and state
    ImageProvider? getImageProvider() {
      if (_pickedImage != null) {
        if (kIsWeb) {
          return NetworkImage(_pickedImage!.path);
        } else {
          return FileImage(File(_pickedImage!.path));
        }
      }
      if (profile.profileImage != null && profile.profileImage!.isNotEmpty) {
        return NetworkImage(profile.profileImage!);
      }
      return null;
    }

    return Center(
      child: Column(
        children: [
          CircleAvatar(
            radius: 60,
            backgroundColor: Colors.grey.shade200,
            backgroundImage: getImageProvider() as ImageProvider?,
            child: _pickedImage == null && (profile.profileImage == null || profile.profileImage!.isEmpty)
                ? Icon(Icons.person, size: 60, color: Colors.grey.shade700)
                : null,
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Pick Image Button
              OutlinedButton.icon(
                onPressed: _isLoading ? null : _pickImage,
                icon: const Icon(Icons.image),
                label: const Text('Pick Image'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: primaryColor,
                  side: BorderSide(color: primaryColor),
                ),
              ),
              if (_pickedImage != null) ...[
                const SizedBox(width: 10),
                // Upload Image Button
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _handleImageUpload,
                  icon: _isLoading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.upload),
                  label: Text(_isLoading ? 'Uploading...' : 'Upload Image'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  /// Widget to display and manage feed type selection with search and dynamic data.
  Widget _buildFeedTypeSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search Field
        TextField(
          controller: _feed_typesearchController,
          decoration: const InputDecoration(
            labelText: 'Search Feed Types',
            suffixIcon: Icon(Icons.search),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 10),
        
        // Sorting Options
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            const Text('Sort by:', style: TextStyle(fontSize: 14)),
            const SizedBox(width: 8),
            DropdownButton<String>(
              value: _currentSort,
              items: const [
                DropdownMenuItem(value: 'rank', child: Text('Rank')),
                DropdownMenuItem(value: 'latest', child: Text('Latest')),
                DropdownMenuItem(value: 'alpha', child: Text('A-Z')),
              ],
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _currentSort = newValue;
                  });
                  // Re-fetch feed_types with the new sort method
                  _fetchfeed_types(search: _feed_typesearchController.text);
                }
              },
            ),
          ],
        ),
        const SizedBox(height: 10),
        
        // Tag List Display (FutureBuilder for async data)
        const Text(
          'Available Feed Types (Click to Select/Deselect):', 
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.teal)
        ),
        const SizedBox(height: 8),
        Container(
          constraints: const BoxConstraints(maxHeight: 200), // Max height for scrolling
          padding: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: FutureBuilder<List<TagInfo>>(
            future: _feed_typesFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                // Display error message
                return Center(child: Text('Error loading feed types: ${snapshot.error.toString().replaceFirst('Exception: ', '')}', textAlign: TextAlign.center));
              } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                return SingleChildScrollView(
                  child: Wrap(
                    spacing: 8.0,
                    runSpacing: 4.0,
                    children: snapshot.data!.map((tagInfo) {
                      final tagName = tagInfo.tag;
                      final isSelected = _selectedFeedTypes.contains(tagName);
                      return FilterChip(
                        label: Text(
                          // Show total usage and rank info
                          '#$tagName (${tagInfo.totalUsed} uses)', // Removed rank for brevity, but can be re-added
                          overflow: TextOverflow.ellipsis,
                        ),
                        selected: isSelected,
                        onSelected: (bool selected) {
                          setState(() {
                            if (selected) {
                              _selectedFeedTypes.add(tagName);
                            } else {
                              _selectedFeedTypes.remove(tagName);
                            }
                          });
                        },
                        selectedColor: Colors.teal.shade100,
                        checkmarkColor: Colors.teal.shade900,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.teal.shade900 : Colors.black87,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 12,
                        ),
                        backgroundColor: isSelected ? Colors.teal.shade50 : Colors.grey.shade100,
                        showCheckmark: false, // Use the selected color change as the main indicator
                      );
                    }).toList(),
                  ),
                );
              } else {
                return const Center(child: Text('No feed types found. Try a different search or sort option.'));
              }
            },
          ),
        ),
        
        const SizedBox(height: 20),
        
        // Selected feed_types Summary
        const Text(
          'Currently Subscribed:', 
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8.0,
          runSpacing: 4.0,
          children: _selectedFeedTypes.map((tag) {
            return Chip(
              label: Text(tag),
              deleteIcon: const Icon(Icons.close, size: 18),
              onDeleted: () {
                setState(() {
                  _selectedFeedTypes.remove(tag);
                });
              },
              backgroundColor: Colors.indigo.shade100,
              labelStyle: TextStyle(color: Colors.indigo.shade900, fontWeight: FontWeight.bold),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildReadOnlyField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        initialValue: value,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.grey[100],
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
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
          border: const OutlineInputBorder(),
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
        backgroundColor: Theme.of(context).colorScheme.primary, // Using primary color
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<UserProfile>(
        future: widget.userDataFuture,
        builder: (context, snapshot) {
          // Check if profile is loading OR if it has finished loading but _currentProfile isn't yet set
          if (snapshot.connectionState == ConnectionState.waiting || (_currentProfile == null && snapshot.connectionState != ConnectionState.done)) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error loading profile: ${snapshot.error}', textAlign: TextAlign.center));
          } else if (_currentProfile != null) {
            
            return SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- Profile Image Section ---
                    _buildProfileImageSection(),
                    const SizedBox(height: 30),

                    // --- Non-Editable Fields ---
                    const Text('Account Credentials (Read-Only)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const Divider(height: 10),
                    _buildReadOnlyField('Username', _currentProfile!.username),
                    _buildReadOnlyField('Email', _currentProfile!.email),

                    const SizedBox(height: 20),

                    // --- Editable Fields ---
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
                    
                    // --- Dynamic Feed Types Section ---
                    const Text('Feed Subscriptions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const Divider(height: 10),
                    _buildFeedTypeSelection(),
                    // --- END Dynamic Feed Types Section ---

                    const SizedBox(height: 30),

                    // --- Submit Button for Text Fields ---
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleUpdateProfile,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          backgroundColor: Theme.of(context).colorScheme.secondary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                            : const Text('Save All Details & Subscriptions', style: TextStyle(fontSize: 18)),
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