import 'package:flutter/material.dart';
import 'dart:io'; // Kept for FileImage usage on non-web platforms
import 'package:flutter/foundation.dart' show kIsWeb; // Import for kIsWeb
import 'package:image_picker/image_picker.dart';
import '../services/auth_service.dart';
// Assuming this import is necessary

// Enum for available content types (still useful for UI logic)
enum PostContentType { text, image, video }

class PostCreationScreen extends StatefulWidget {
  final AuthService authService;
  final List<String> availableFeedTypes; // Pass this from UserProfile/API

  const PostCreationScreen({
    super.key,
    required this.authService,
    required this.availableFeedTypes,
  });

  @override
  State<PostCreationScreen> createState() => _PostCreationScreenState();
}

class _PostCreationScreenState extends State<PostCreationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();

  // Form Data State
  PostContentType _contentType = PostContentType.text;
  String _textContent = '';

  // 🔥 FIX 1: Use XFile? for the actual file object passed to the API
  XFile? _xFileMedia;

  // For native mobile preview (can be null on web or if no file is selected)
  File? _mediaFilePreview;

  List<String> _selectedFeedTypes = [];

  bool _isLoading = false;

  // --- Utility Methods ---

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // --- File Picking Logic ---

  Future<void> _showMediaPickerDialog() async {
    final choice = await showDialog<PostContentType>(
      context: context,
      builder: (BuildContext context) {
        return SimpleDialog(
          title: const Text('Select Media Type'),
          children: <Widget>[
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(context, PostContentType.image);
              },
              child: const Text('Image'),
            ),
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(context, PostContentType.video);
              },
              child: const Text('Video'),
            ),
          ],
        );
      },
    );

    if (choice != null) {
      await _pickMedia(choice);
    }
  }

  Future<void> _pickMedia(PostContentType type) async {
    XFile? pickedFile;
    if (type == PostContentType.image) {
      pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    } else if (type == PostContentType.video) {
      pickedFile = await _picker.pickVideo(source: ImageSource.gallery);
    }

    if (pickedFile != null) {
      setState(() {
        _xFileMedia = pickedFile;
        _contentType = type;

        // 🔥 FIX 2: Correctly handle File/XFile for cross-platform compatibility.
        // dart:io.File creation is skipped on web (kIsWeb) to prevent errors.
        if (!kIsWeb) {
          try {
            final String? pickedPath = pickedFile?.path;
            if (pickedPath != null && pickedPath.isNotEmpty) {
              _mediaFilePreview = File(pickedPath);
            } else {
              _mediaFilePreview = null;
            }
          } catch (e) {
            _mediaFilePreview = null;
          }
        } else {
          _mediaFilePreview = null; // No dart:io.File on web
        }
      });
    }
  }

  void _removeMedia() {
    setState(() {
      _xFileMedia = null;
      _mediaFilePreview = null;
      _contentType = PostContentType.text;
    });
  }

  // --- Submission Logic ---

  Future<void> _submitPost() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    _formKey.currentState!.save();

    // Final checks before API call
    if (_textContent.isEmpty && _xFileMedia == null) {
      _showSnackBar('Post content cannot be empty. Please add text or a media file.');
      return;
    }

    if (_selectedFeedTypes.isEmpty) {
      _showSnackBar('Please select at least one tag/feed type.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final primaryFeedType = _selectedFeedTypes.first;

    try {
      // API call to AuthService.createContentPost
      await widget.authService.createContentPost(
        text: _textContent,
        feedType: primaryFeedType,
        mediaFile: _xFileMedia,
      );

      _showSnackBar('Post created successfully!');
      // Navigate back to the home screen and trigger a refresh
      Navigator.of(context).pop(true);

    } catch (e) {
      _showSnackBar('Failed to create post: ${e.toString().split(':').last.trim()}');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // --- UI Builders ---

  Widget _buildMediaPickerAndPreview() {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _xFileMedia == null
                      ? 'No media file attached.'
                      : 'File: ${_xFileMedia!.name} (${_contentType.toString().split('.').last.toUpperCase()})',
                  style: const TextStyle(fontStyle: FontStyle.italic),
                ),
              ),
              const SizedBox(width: 8),
              // Use dialog to choose between image/video
              ElevatedButton.icon(
                onPressed: _showMediaPickerDialog,
                icon: const Icon(Icons.add_photo_alternate),
                label: const Text('Add Media'),
              ),
              if (_xFileMedia != null)
                Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.red),
                    onPressed: _removeMedia,
                    tooltip: 'Remove Media',
                  ),
                ),
            ],
          ),
          // 🔥 FIX 3: Cross-platform Media Preview
          if (_xFileMedia != null)
            Container(
              margin: const EdgeInsets.only(top: 10),
              child: _mediaFilePreview != null && _contentType == PostContentType.image
                  // Mobile/Desktop Image Preview
                  ? Container(
                      height: 150,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                        image: DecorationImage(
                          image: FileImage(_mediaFilePreview!),
                          fit: BoxFit.contain,
                        ),
                      ),
                    )
                  // Web or Video Preview Placeholder
                  : Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.grey[200],
                      ),
                      child: Center(
                        child: Text(
                          _contentType == PostContentType.video
                              ? 'Video Preview Not Available (File: ${_xFileMedia!.name})'
                              : 'File Selected (Web or Unsupported Preview)',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
            ),
        ],
      ),
    );
  }

  Widget _buildTagSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 16.0, bottom: 8.0),
          child: Text('Primary Feed Type (Select ONE tag):', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        Wrap(
          spacing: 8.0,
          runSpacing: 4.0,
          children: widget.availableFeedTypes.map((tag) {
            final isSelected = _selectedFeedTypes.contains(tag);
            return FilterChip(
              label: Text(tag),
              selected: isSelected,
              onSelected: (bool selected) {
                setState(() {
                  if (selected) {
                    // Only allow one to be selected
                    _selectedFeedTypes = [tag];
                  } else {
                    _selectedFeedTypes.remove(tag);
                  }
                });
              },
              // Visual cue for single selection requirement
              selectedColor: Colors.teal.withOpacity(0.7),
              checkmarkColor: Colors.white,
            );
          }).toList(),
        ),
        if (_selectedFeedTypes.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 4.0),
            child: Text('Selection required', style: TextStyle(color: Colors.red, fontSize: 12)),
          )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Determine the label and maxLines based on media presence
    final isMediaAttached = _xFileMedia != null;
    final textLabel = isMediaAttached ? 'Caption/Text Content (Optional)' : 'Main Text Content';
    final maxLines = isMediaAttached ? 3 : 10;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Post'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // 1. Media Picker and Preview
              _buildMediaPickerAndPreview(),
              const SizedBox(height: 16),

              // 2. Text Content (Caption or Main Content)
              TextFormField(
                decoration: InputDecoration(
                  labelText: textLabel,
                  alignLabelWithHint: true, // Useful for multi-line
                  border: const OutlineInputBorder(),
                ),
                maxLines: maxLines,
                onSaved: (value) {
                  _textContent = value ?? '';
                },
                validator: (value) {
                  // Require text only if no media file is attached.
                  if (!isMediaAttached && (value == null || value.isEmpty)) {
                    return 'Please enter content for the post.';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // 3. Tag Selector
              _buildTagSelector(),

              const SizedBox(height: 30),

              // 4. Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _submitPost,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.send),
                  label: Text(_isLoading ? 'Posting...' : 'Create Post'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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