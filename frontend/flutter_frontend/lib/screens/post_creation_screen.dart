import 'package:flutter/material.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
// 1. ADD VIDEO PLAYER IMPORT
import 'package:video_player/video_player.dart';

import '../services/auth_service.dart';

// Enum for available content types (Text is the default/fallback)
enum PostContentType { text, image, video }

class PostCreationScreen extends StatefulWidget {
  final AuthService authService;
  final List<String> availableFeedTypes; 

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

  // XFile? is used for the actual file object passed to the API (cross-platform compatible)
  XFile? _xFileMedia;
  
  // 2. ADD VIDEO CONTROLLER STATE
  VideoPlayerController? _videoController;
  Future<void>? _initializeVideoPlayerFuture;

  // State for the selected feed types (now allowing multiple)
  List<String> _selectedFeedTypes = [];

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedFeedTypes = [];
  }
  
  // 3. CLEAN UP RESOURCES
  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

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
          title: const Text('Select Media Type to Attach'),
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
      // Dispose of old controller if a new file is picked
      _videoController?.dispose();
      _videoController = null;
      _initializeVideoPlayerFuture = null;

      setState(() {
        _xFileMedia = pickedFile;
        _contentType = type;
        
        // 4. INITIALIZE VIDEO CONTROLLER FOR VIDEO FILES
        if (type == PostContentType.video) {
          if (kIsWeb) {
            // Web uses the XFile path as a network/blob URL
            if (pickedFile != null) {
              _videoController = VideoPlayerController.networkUrl(Uri.parse(pickedFile.path));
            }
          } else {
            // Mobile/Desktop uses the file path
            if (pickedFile != null) {
              _videoController = VideoPlayerController.file(File(pickedFile.path));
            }
          }
          
          _initializeVideoPlayerFuture = _videoController?.initialize().then((_) {
            // Ensure the first frame is shown and the controller is ready.
            if (mounted) setState(() {});
          });
          _videoController?.setLooping(true);
        }
      });
    }
  }

  void _removeMedia() {
    // Dispose of the controller when media is removed
    _videoController?.dispose();
    _videoController = null;
    _initializeVideoPlayerFuture = null;
    
    setState(() {
      _xFileMedia = null;
      _contentType = PostContentType.text;
    });
  }

  // --- Submission Logic (Unchanged) ---

  Future<void> _submitPost() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    _formKey.currentState!.save();

    if (_textContent.isEmpty && _xFileMedia == null) {
      _showSnackBar('Post content cannot be empty. Please add text or a media file.');
      return;
    }

    if (_selectedFeedTypes.isEmpty) {
      _showSnackBar('Please select at least one feed type/tag.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await widget.authService.createContentPost(
        text: _textContent,
        feedTypes: _selectedFeedTypes,
        mediaFile: _xFileMedia,
      );

      _showSnackBar('Post created successfully!');
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      debugPrint('Post creation failed: $e');
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
  
  // Helper widget for video controls
  Widget _buildVideoControls() {
    return Center(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(50),
        ),
        child: IconButton(
          icon: Icon(
            _videoController!.value.isPlaying ? Icons.pause : Icons.play_arrow,
            color: Colors.white,
            size: 30,
          ),
          onPressed: () {
            setState(() {
              _videoController!.value.isPlaying
                  ? _videoController!.pause()
                  : _videoController!.play();
            });
          },
        ),
      ),
    );
  }

  Widget _buildMediaPickerAndPreview() {
    final fileName = _xFileMedia?.name ?? 'No media file attached.';
    final fileType = _contentType.toString().split('.').last.toUpperCase();

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
                      ? fileName
                      : 'File: $fileName ($fileType)',
                  style: const TextStyle(fontStyle: FontStyle.italic, overflow: TextOverflow.ellipsis),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: _showMediaPickerDialog,
                icon: const Icon(Icons.add_photo_alternate, size: 18),
                label: const Text('Add Media'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.teal,
                  side: const BorderSide(color: Colors.teal),
                ),
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
          
          // --- IMAGE PREVIEW BLOCK (Unchanged) ---
          if (_xFileMedia != null && _contentType == PostContentType.image)
            Container(
              margin: const EdgeInsets.only(top: 10),
              height: 150,
              decoration: BoxDecoration(
                color: Colors.grey[200], 
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Center( 
                  child: kIsWeb
                      ? Image.network(
                          _xFileMedia!.path,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) => _buildPlaceholder('IMAGE'),
                        )
                      : Image.file(
                          File(_xFileMedia!.path),
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) => _buildPlaceholder('IMAGE'),
                        ),
                ),
              ),
            )
          
          // 5. VIDEO PREVIEW BLOCK (New Logic)
          else if (_xFileMedia != null && _contentType == PostContentType.video)
            FutureBuilder(
              future: _initializeVideoPlayerFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  // If the VideoPlayerController has finished initialization, use
                  // the data it provides to limit the aspect ratio of the video.
                  return Container(
                    margin: const EdgeInsets.only(top: 10),
                    decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: AspectRatio(
                        aspectRatio: _videoController!.value.aspectRatio,
                        child: Stack(
                          alignment: Alignment.center,
                          children: <Widget>[
                            VideoPlayer(_videoController!),
                            // Add a subtle overlay for better control visibility
                            Positioned.fill(
                                child: Container(color: Colors.black.withOpacity(0.1))
                            ),
                            // Custom controls
                            _buildVideoControls(), 
                          ],
                        ),
                      ),
                    ),
                  );
                } else {
                  // Show a loading spinner or a simple placeholder while the video is initializing.
                  return Container(
                    margin: const EdgeInsets.only(top: 10),
                    height: 150,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.grey[100],
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(strokeWidth: 2),
                          const SizedBox(height: 10),
                          Text('Initializing $fileType Preview...',
                              style: TextStyle(color: Colors.grey.shade700)),
                        ],
                      ),
                    ),
                  );
                }
              },
            )
          // 6. FALLBACK FOR OTHER MEDIA TYPES (Placeholder for unexpected files)
          else if (_xFileMedia != null)
             Container(
              margin: const EdgeInsets.only(top: 10),
              height: 150, 
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey[100],
              ),
              child: _buildPlaceholder(fileType),
            ),
        ],
      ),
    );
  }
  
  // This placeholder is now only for error cases or non-video/non-image files
  Widget _buildPlaceholder(String fileType) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(fileType == 'VIDEO' ? Icons.videocam : Icons.photo, size: 40, color: Colors.grey.shade600),
          const SizedBox(height: 8),
          Text(
            '$fileType File Selected.\n(Preview not supported in this context)',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade700, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }


  Widget _buildTagSelector() {
    // ... (Unchanged)
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 16.0, bottom: 8.0),
          child: Text('Select one or more relevant tags (Feed Types):', style: TextStyle(fontWeight: FontWeight.bold)),
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
                    _selectedFeedTypes.add(tag);
                  } else {
                    _selectedFeedTypes.remove(tag);
                  }
                });
              },
              selectedColor: Colors.teal.shade400,
              checkmarkColor: Colors.white,
              labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black87),
              backgroundColor: isSelected ? Colors.teal.shade100 : Colors.grey.shade200,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: isSelected ? Colors.teal.shade600 : Colors.grey.shade300),
              ),
            );
          }).toList(),
        ),
        if (_selectedFeedTypes.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 4.0),
            child: Text('Please select at least one tag.', style: TextStyle(color: Colors.red, fontSize: 12)),
          )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // ... (Unchanged)
    final isMediaAttached = _xFileMedia != null;
    final textLabel = isMediaAttached ? 'Caption/Text Content (Optional)' : 'Main Text Content';
    final maxLines = isMediaAttached ? 4 : 8;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Post'),
        backgroundColor: Colors.teal.shade700,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _buildMediaPickerAndPreview(),
              const SizedBox(height: 24),
              TextFormField(
                decoration: InputDecoration(
                  labelText: textLabel,
                  alignLabelWithHint: true,
                  hintText: isMediaAttached ? 'Add a descriptive caption...' : 'What\'s on your mind?',
                  border: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: const BorderRadius.all(Radius.circular(12)),
                    borderSide: BorderSide(color: Colors.teal.shade500, width: 2),
                  ),
                ),
                minLines: 1,
                maxLines: maxLines,
                onSaved: (value) {
                  _textContent = value ?? '';
                },
                validator: (value) {
                  if (!isMediaAttached && (value == null || value.trim().isEmpty)) {
                    return 'Please enter content for the post.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              _buildTagSelector(),
              const SizedBox(height: 40),
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
                      : const Icon(Icons.send_rounded),
                  label: Text(_isLoading ? 'Posting...' : 'Create Post'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
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