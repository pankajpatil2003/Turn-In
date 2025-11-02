import 'package:flutter/material.dart';
import '../models/comment_model.dart';
import '../models/content_model.dart'; // Ensure this is imported for ContentPost
import '../services/auth_service.dart';

class CommentScreen extends StatefulWidget {
  final ContentPost post;

  const CommentScreen({super.key, required this.post});

  @override
  State<CommentScreen> createState() => _CommentScreenState();
}

class _CommentScreenState extends State<CommentScreen> {
  // Assuming AuthService handles the API communication
  final AuthService _authService = AuthService(); 
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _inputFocusNode = FocusNode();

  Future<List<CommentModel>>? _commentsFuture;

  // State for posting and replying
  int? _replyingToCommentId;
  String _replyingToUsername = '';
  bool _isPosting = false;

  @override
  void initState() {
    super.initState();
    _fetchComments();
    // Re-render the widget when text changes to update the send button state
    _commentController.addListener(() => setState(() {})); 
  }

  @override
  void dispose() {
    _commentController.dispose();
    _inputFocusNode.dispose();
    super.dispose();
  }

  /// Fetches comments for the current post.
  void _fetchComments() {
    setState(() {
      // ✅ Confirmed: Convert int ID to String for the service parameter
      _commentsFuture =
          _authService.fetchCommentsForContent(widget.post.id.toString());
    });
  }

  /// Handles posting a new comment or a reply.
  void _postComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty || _isPosting) return;

    final targetCommentId = _replyingToCommentId;

    // Clear input and reset state immediately for a responsive feel
    _commentController.clear();
    _resetReplyState();

    // Show loading state
    setState(() {
      _isPosting = true;
    });

    try {
      await _authService.postComment(
        // ✅ Confirmed: Convert int ID to String for the service parameter
        widget.post.id.toString(),
        text,
        targetCommentId,
      );

      // Re-fetch comments to update the list with the new comment
      _fetchComments();
    } catch (e) {
      if (mounted) {
        // Display a user-friendly error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Failed to post comment: ${e.toString().split(':').last.trim()}'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPosting = false;
        });
      }
    }
  }

  /// Sets the state to reply to a specific comment.
  void _setReplyState(int commentId, String username) {
    setState(() {
      // If the user taps the same reply button, reset it.
      if (_replyingToCommentId == commentId) {
        _resetReplyState();
      } else {
        _replyingToCommentId = commentId;
        _replyingToUsername = username;
        _commentController.text = '@$username '; // Pre-fill the input
        _commentController.selection = TextSelection.fromPosition(
            TextPosition(offset: _commentController.text.length));
        // Request focus to pop up the keyboard
        _inputFocusNode.requestFocus();
      }
    });
  }

  /// Resets the replying-to state.
  void _resetReplyState() {
    setState(() {
      _replyingToCommentId = null;
      _replyingToUsername = '';
      // Only clear if the user hasn't typed beyond the pre-filled username
      if (_commentController.text.startsWith('@')) {
        _commentController.clear();
      }
    });
  }

  // -------------------------------------------------------------------
  // --- Recursive Widget to Build Comment Tree ---
  // -------------------------------------------------------------------

  Widget _buildComment(CommentModel comment) {
    // Assumption: CommentModel.user is of type CommentUser, which has
    // the correct 'profileImageUrl' field.
    final profileImageUrl = comment.user.profileImageUrl;

    return Padding(
      padding: EdgeInsets.only(
        // Indent replies
        left: comment.parentCommentId != null ? 36.0 : 16.0,
        right: 16.0,
        top: 8.0,
        bottom: 4.0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User Avatar
              CircleAvatar(
                radius: 16,
                backgroundColor: Colors.blueGrey.shade100,
                backgroundImage: (profileImageUrl?.isNotEmpty ?? false)
                    ? NetworkImage(profileImageUrl!) as ImageProvider
                    : null,
                child: profileImageUrl == null || profileImageUrl.isEmpty
                    ? Text(
                        comment.user.username[0].toUpperCase(),
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.bold),
                      )
                    : null,
              ),
              const SizedBox(width: 8),

              // Comment Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Username and Time Ago
                    Row(
                      children: [
                        Text(
                          comment.user.username,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          // Assuming CommentModel has a formattedTimeAgo getter
                          comment.formattedTimeAgo, 
                          style:
                              const TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    // Comment Text
                    Text(
                      comment.text,
                      style:
                          const TextStyle(fontSize: 14.5, color: Colors.black87),
                    ),
                    // Reply Link
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: InkWell(
                        onTap: () =>
                            _setReplyState(comment.id, comment.user.username),
                        child: Text(
                          'Reply',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Recursively build replies, indented
          if (comment.replies.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: comment.replies.length,
                itemBuilder: (context, index) {
                  // Recursive call
                  return _buildComment(comment.replies[index]);
                },
              ),
            ),

          // Divider for top-level comments only
          if (comment.parentCommentId == null)
            const Divider(height: 16, indent: 40, endIndent: 16),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------
  // --- Main Build Method ---
  // -------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.post.commentCount} Comments'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        elevation: 1,
      ),
      body: Column(
        children: [
          // Comment List
          Expanded(
            child: FutureBuilder<List<CommentModel>>(
              future: _commentsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'Failed to load comments: ${snapshot.error.toString().split(':').last.trim()}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  );
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('Be the first to comment! 🚀'));
                }

                // If data exists, show the list.
                return ListView.builder(
                  padding: const EdgeInsets.only(top: 12.0, bottom: 8.0),
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    final comment = snapshot.data![index];
                    return _buildComment(comment);
                  },
                );
              },
            ),
          ),

          // Comment Input Box
          Container(
            padding: EdgeInsets.only(
              left: 10.0,
              right: 10.0,
              // Adjust for keyboard
              bottom: MediaQuery.of(context).viewInsets.bottom + 8.0, 
              top: 4.0,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              border: Border(
                  top: BorderSide(color: Colors.grey.shade300, width: 0.5)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Replying To indicator
                if (_replyingToCommentId != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4.0, top: 4.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Replying to: @$_replyingToUsername',
                          style: TextStyle(
                              color: Colors.blue.shade600,
                              fontSize: 13,
                              fontWeight: FontWeight.w500),
                        ),
                        GestureDetector(
                          onTap: _resetReplyState,
                          child:
                              const Icon(Icons.close, size: 18, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                // Input and Send button
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _commentController,
                        focusNode: _inputFocusNode,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: InputDecoration(
                          hintText: 'Add a comment...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25.0),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Conditional Send Button/Loading Indicator
                    if (_isPosting)
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10.0),
                        child: SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.5, color: Colors.teal),
                        ),
                      )
                    else
                      IconButton(
                        icon: Icon(Icons.send,
                            color: _commentController.text.trim().isNotEmpty
                                ? Colors.teal
                                : Colors.grey,
                            size: 28),
                        onPressed: _commentController.text.trim().isNotEmpty &&
                                !_isPosting
                            ? _postComment
                            : null,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}