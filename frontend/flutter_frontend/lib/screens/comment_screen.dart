import 'package:flutter/material.dart';
import '../models/comment_model.dart';
import '../models/content_model.dart';
import '../services/auth_service.dart';

class CommentScreen extends StatefulWidget {
  final ContentPost post;
  // FIX 1: Add the required callback parameter for the parent screen (HomeScreen)
  final ValueChanged<int> onCountUpdated; 

  const CommentScreen({
    super.key, 
    required this.post,
    // FIX 1: Require the callback in the constructor
    required this.onCountUpdated, 
  });

  @override
  State<CommentScreen> createState() => _CommentScreenState();
}

class _CommentScreenState extends State<CommentScreen> {
  final AuthService _authService = AuthService();
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _inputFocusNode = FocusNode();

  Future<List<CommentModel>>? _commentsFuture;
  // Hold the current comment count to pass back to the parent
  int _currentCommentCount = 0; 

  int? _replyingToCommentId;
  String _replyingToUsername = '';
  String _prefilledReplyText = '';
  bool _isPosting = false;

  @override
  void initState() {
    super.initState();
    // Initialize the local count from the post data
    _currentCommentCount = widget.post.commentCount; 
    _fetchComments();
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
      _commentsFuture =
          _authService.fetchCommentsForContent(widget.post.id.toString());
      // Add logic to update the local comment count based on the *server's total count*
      // or, as a fallback, the total number of items if the API only returns a flat list.
      _commentsFuture!.then((comments) {
        if (!mounted) return;
        // NOTE: Ideally, the API response for fetchCommentsForContent should include 
        // the *total* number of comments (including replies).
        // Since the model doesn't show a total count field, we'll keep the current
        // count and trust the manual increment/decrement for now, but remove the
        // confusing old comment block.
      }).catchError((_) {
        // Error handling already done in FutureBuilder
      });
    });
  }

  /// Handles posting a new comment or a reply.
  void _postComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty || _isPosting) return;

    final targetCommentId = _replyingToCommentId;

    // Clear text field and reset state before the async operation
    _commentController.clear();
    _resetReplyState();
    _inputFocusNode.unfocus();

    setState(() {
      _isPosting = true;
    });

    try {
      // Assume the API call returns the newly created comment or a success signal.
      // If the API returns the *new total count*, you would use that instead of manual increment.
      await _authService.postComment(
        widget.post.id.toString(),
        text,
        // FIX 3: Convert int? to String? for the service parameter
        targetCommentId?.toString(),
      );

      // On successful post:
      // 1. Refresh the list of comments
      _fetchComments();

      // 2. Increment the local count and notify the parent (HomeScreen)
      // FIX: Only increment if this is a ROOT comment. 
      // If it's a reply, the root count *shouldn't* increment in most social app contexts.
      // However, if your 'commentCount' includes all replies (total items), 
      // then the manual increment is correct. Assuming 'commentCount' is 'total items'.
      final newCount = _currentCommentCount + 1;
      _currentCommentCount = newCount;
      // FIX 2: Call the callback function to update the count in the parent widget (HomeScreen)
      widget.onCountUpdated(newCount); 

    } catch (e) {
      if (mounted) {
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

  void _setReplyState(int commentId, String username) {
    setState(() {
      if (_replyingToCommentId == commentId) {
        _resetReplyState();
      } else {
        _replyingToCommentId = commentId;
        _replyingToUsername = username;
        _prefilledReplyText = '@$username ';
        _commentController.text = _prefilledReplyText;
        _commentController.selection = TextSelection.fromPosition(
            TextPosition(offset: _commentController.text.length));
        _inputFocusNode.requestFocus();
      }
    });
  }

  void _resetReplyState() {
    setState(() {
      // Only clear the controller if the text hasn't been modified past the prefilled text
      if (_commentController.text == _prefilledReplyText) {
        _commentController.clear();
      } else if (_commentController.text.startsWith(_prefilledReplyText)) {
        // If the user modified the text, just remove the prefilled part 
      // when cancelling the reply, or leave it if they've written content.
      // For simplicity, we'll stick to the original logic: if they cancel, 
      // they probably want to clear the prefill.
       _commentController.text = _commentController.text.substring(_prefilledReplyText.length).trimLeft();
      }
      _replyingToCommentId = null;
      _replyingToUsername = '';
      _prefilledReplyText = '';
    });
  }

  // -------------------------------------------------------------------
  // --- Recursive Widget to Build Comment Tree ---
  // -------------------------------------------------------------------

  Widget _buildComment(CommentModel comment) {
    // FIX 1: Reverted to profileImageUrl as the field name
    final profileImageUrl = comment.user.profileImageUrl; 

    return Padding(
      key: ValueKey(comment.id), 
      padding: EdgeInsets.only(
        // Use different left padding for replies
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
                        // FIX 2: Changed comment.creator to comment.user
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
                        // FIX 2: Changed comment.creator to comment.user
                        Text(
                          comment.user.username,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const SizedBox(width: 8),
                        Text(
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
                        // FIX 2: Changed comment.creator to comment.user
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

          if (comment.replies.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: comment.replies
                    .map((reply) => _buildComment(reply))
                    .toList(),
              ),
            ),

          // Only show a divider for root comments to separate them
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
        // Use the locally updated count for the title
        title: Text('$_currentCommentCount Comments'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        elevation: 1,
      ),
      body: Column(
        children: [
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
                  // FIX: Add a small check to ensure the count is zero if the list is empty
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted && _currentCommentCount != 0) {
                      setState(() {
                        _currentCommentCount = 0;
                        widget.onCountUpdated(0);
                      });
                    }
                  });
                  return const Center(child: Text('Be the first to comment! 🚀'));
                }

                // Update the local count and notify the parent if the fetched list size is different
                // This logic relies on the API returning a flat list of ALL comments/replies
                // or a special, aggregated list. Since the data is recursive, 
                // snapshot.data!.length is only the count of ROOT comments.
                // We'll trust the manual increment in _postComment for a simpler but less safe approach.
                // Keeping the old logic for now, but commenting out to avoid unnecessary setState calls
                /*
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  final totalCount = _calculateTotalComments(snapshot.data!);
                  if (mounted && totalCount != _currentCommentCount) {
                    setState(() {
                      _currentCommentCount = totalCount;
                      widget.onCountUpdated(totalCount);
                    });
                  }
                });
                */
                // New FIX: A helper function to safely calculate the total count from the recursive list
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  final calculatedCount = _calculateTotalComments(snapshot.data!);
                  if (mounted && calculatedCount != _currentCommentCount) {
                    setState(() {
                      _currentCommentCount = calculatedCount;
                      widget.onCountUpdated(calculatedCount);
                    });
                  }
                });

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

          Container(
            padding: EdgeInsets.only(
              left: 10.0,
              right: 10.0,
              // Adjust padding when keyboard is visible
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

  // New helper function to recursively calculate the total number of comments and replies
  int _calculateTotalComments(List<CommentModel> comments) {
    int total = 0;
    for (var comment in comments) {
      total += 1; // Count the current comment
      total += _calculateTotalComments(comment.replies); // Recursively add replies
    }
    return total;
  }
}