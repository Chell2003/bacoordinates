import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:untitled/providers/theme_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:untitled/providers/auth_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';

class PostDetailPage extends StatefulWidget {
  final Map<String, dynamic> post;
  final String postId;
  final Function(String, Map<String, dynamic>) onLike;

  const PostDetailPage({
    super.key,
    required this.post,
    required this.postId,
    required this.onLike,
  });

  @override
  State<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends State<PostDetailPage> {
  final commentController = TextEditingController();
  final replyController = TextEditingController();
  final ValueNotifier<String?> replyingToId = ValueNotifier<String?>(null);
  final ValueNotifier<String?> replyingToName = ValueNotifier<String?>(null);
  File? _commentImage;
  File? _replyImage;
  final ImagePicker _picker = ImagePicker();
  final Map<String, bool> _expandedComments = {};

  // Cloudinary configuration
  final String cloudinaryUrl = "https://api.cloudinary.com/v1_1/ds8esjc0y/image/upload";
  final String uploadPreset = "flutter_upload";

  @override
  void dispose() {
    commentController.dispose();
    replyController.dispose();
    replyingToId.dispose();
    replyingToName.dispose();
    super.dispose();
  }

  // Function to upload image to Cloudinary
  Future<String?> _uploadImageToCloudinary(File imageFile) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse(cloudinaryUrl));
      request.fields['upload_preset'] = uploadPreset;
      request.files.add(
        await http.MultipartFile.fromPath('file', imageFile.path),
      );

      final response = await request.send();
      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        final jsonData = json.decode(responseData);
        return jsonData['secure_url'];
      }
      return null;
    } catch (e) {
      debugPrint('Error uploading to Cloudinary: $e');
      return null;
    }
  }

  Future<void> _pickImage(bool isReply) async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        if (isReply) {
          _replyImage = File(pickedFile.path);
        } else {
          _commentImage = File(pickedFile.path);
        }
      });
    }
  }

  Future<void> _removeImage(bool isReply) async {
    setState(() {
      if (isReply) {
        _replyImage = null;
      } else {
        _commentImage = null;
      }
    });
  }

  Future<String?> _getUserName(String uid) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (doc.exists) {
        return doc.data()?['username'];
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<void> _addComment(BuildContext context, String comment, {String? parentId, File? image}) async {
    try {
      final user = context.read<AuthProvider>().user;
      if (user == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('You need to sign in to comment')),
          );
        }
        return;
      }

      String? username;
      if (user.providerData.isNotEmpty && user.providerData[0].providerId != 'google.com') {
        username = await _getUserName(user.uid);
      }

      final authorName = user.displayName?.isNotEmpty == true
          ? user.displayName
          : (username ?? 'Anonymous');

      // Upload image to Cloudinary if exists
      String? imageUrl;
      if (image != null) {
        imageUrl = await _uploadImageToCloudinary(image);
        if (imageUrl == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed to upload image')),
            );
          }
          return;
        }
      }

      await FirebaseFirestore.instance
          .collection('forums')
          .doc(widget.postId)
          .collection('comments')
          .add({
        'content': comment,
        'authorId': user.uid,
        'authorName': authorName,
        'authorAvatar': user.photoURL,
        'createdAt': FieldValue.serverTimestamp(),
        'parentId': parentId,
        'hasImage': image != null,
        'imageUrl': imageUrl,
        'repliedToName': parentId != null ? replyingToName.value : null,// Store Cloudinary URL
      });

      await FirebaseFirestore.instance
          .collection('forums')
          .doc(widget.postId)
          .update({
        'comments': FieldValue.increment(1),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Comment added successfully!'),
            duration: Duration(seconds: 2),
          ),
        );

        if (parentId == null) {
          commentController.clear();
          setState(() => _commentImage = null);
        } else {
          replyController.clear();
          setState(() => _replyImage = null);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding comment: ${e.toString()}')),
        );
      }
    }
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return '';

    final DateTime date;
    if (timestamp is Timestamp) {
      date = timestamp.toDate();
    } else {
      try {
        date = timestamp.toDate();
      } catch (e) {
        return '';
      }
    }

    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  Widget _buildCommentWithReplies(
      BuildContext context,
      Map<String, dynamic> comment,
      String commentId, {
        bool isFirstLevelReply = false,
      }) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.only(left: isFirstLevelReply ? 37.0 : 5.0),
          child: _buildCommentWidget(context, comment, commentId),
        ),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('forums')
              .doc(widget.postId)
              .collection('comments')
              .where('parentId', isEqualTo: commentId)
              .orderBy('createdAt')
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const SizedBox.shrink();

            final replies = snapshot.data!.docs;
            if (replies.isEmpty) return const SizedBox.shrink();

            return Column(
              children: replies.map((doc) {
                final reply = doc.data() as Map<String, dynamic>;
                return _buildCommentWithReplies(
                  context,
                  reply,
                  doc.id,
                  isFirstLevelReply: true, // All nested replies get 76px
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildCommentWidget(
      BuildContext context,
      Map<String, dynamic> comment,
      String commentId,
      ) {
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;
    final theme = Theme.of(context);
    final user = context.read<AuthProvider>().user;
    final isUserComment = user != null && comment['authorId'] == user.uid;
    final hasImage = comment['hasImage'] == true;
    final isReply = comment['parentId'] != null;
    final repliedToName = comment['repliedToName'];

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 16,
                backgroundImage: comment['authorAvatar'] != null
                    ? NetworkImage(comment['authorAvatar'])
                    : null,
                backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                child: comment['authorAvatar'] == null
                    ? Text(
                  comment['authorName']?.toString().isNotEmpty == true
                      ? comment['authorName'].toString()[0].toUpperCase()
                      : 'A',
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          comment['authorName'] ?? 'Anonymous',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (isUserComment) ...[
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'You',
                              style: TextStyle(
                                fontSize: 12,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (isReply && repliedToName != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Reply to $repliedToName',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDarkMode ? Colors.grey[500] : Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isDarkMode ? Colors.grey[850] : Colors.grey[200],
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            comment['content'] ?? '',
                            style: TextStyle(
                              color: isDarkMode ? Colors.grey[300] : Colors.grey[800],
                            ),
                          ),
                          if (hasImage && comment['imageUrl'] != null) ...[
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                comment['imageUrl'],
                                height: 200,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Container(
                                    height: 200,
                                    color: isDarkMode ? Colors.grey[800] : Colors.grey[300],
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        value: loadingProgress.expectedTotalBytes != null
                                            ? loadingProgress.cumulativeBytesLoaded /
                                            (loadingProgress.expectedTotalBytes ?? 1)
                                            : null,
                                      ),
                                    ),
                                  );
                                },
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    height: 200,
                                    color: isDarkMode ? Colors.grey[800] : Colors.grey[300],
                                    child: Center(
                                      child: Icon(
                                        Icons.broken_image,
                                        size: 48,
                                        color: isDarkMode ? Colors.grey[600] : Colors.grey[500],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          _formatTimestamp(comment['createdAt']),
                          style: TextStyle(
                              fontSize: 12,
                              color: isDarkMode ? Colors.grey[500] : Colors.grey[600]
                          ),
                        ),
                        const SizedBox(width: 16),
                        InkWell(
                          onTap: () {
                            replyingToId.value = commentId;
                            replyingToName.value = comment['authorName'] ?? 'Anonymous';
                          },
                          child: Text(
                            'Reply',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }


  Widget _buildImageAttachment(bool isReply) {
    final image = isReply ? _replyImage : _commentImage;
    if (image == null) return const SizedBox.shrink();

    return Stack(
      children: [
        Container(
          height: 100,
          width: 100,
          margin: const EdgeInsets.only(top: 8, bottom: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            image: DecorationImage(
              image: FileImage(image),
              fit: BoxFit.cover,
            ),
          ),
        ),
        Positioned(
          top: 0,
          right: 0,
          child: GestureDetector(
            onTap: () => _removeImage(isReply),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.close,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInputField(bool isReply) {
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;
    final theme = Theme.of(context);
    final controller = isReply ? replyController : commentController;
    final image = isReply ? _replyImage : _commentImage;

    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            IconButton(
              icon: Icon(Icons.image, color: theme.colorScheme.primary),
              onPressed: () => _pickImage(isReply),
            ),
            Expanded(
              child: TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: isReply ? 'Write a reply...' : 'Add a comment...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                textCapitalization: TextCapitalization.sentences,
                minLines: 1,
                maxLines: 4,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.all(5),
                ),
                onPressed: () async {
                  final text = controller.text.trim();
                  if (text.isNotEmpty || image != null) {
                    await _addComment(
                      context,
                      text,
                      parentId: isReply ? replyingToId.value : null,
                      image: image,
                    );
                  }
                },
                child: Icon(
                  isReply ? Icons.reply : Icons.send,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
        _buildImageAttachment(isReply),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;
    final theme = Theme.of(context);
    final user = context.read<AuthProvider>().user;
    final List<dynamic> likedBy = widget.post['likedBy'] ?? [];
    final bool hasUserLiked = user != null && likedBy.contains(user.uid);
    final bool isUserPost = user != null && widget.post['authorId'] == user.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Discussion'),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Column(
          children: [
            Expanded(
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundImage: widget.post['authorAvatar'] != null
                                    ? NetworkImage(widget.post['authorAvatar'])
                                    : null,
                                backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                                child: widget.post['authorAvatar'] == null
                                    ? Text(
                                  widget.post['authorName']?.toString().isNotEmpty == true
                                      ? widget.post['authorName'].toString()[0].toUpperCase()
                                      : 'A',
                                  style: TextStyle(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                                    : null,
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        widget.post['authorName'] ?? 'Anonymous',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      if (isUserPost) ...[
                                        const SizedBox(width: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: theme.colorScheme.primary.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            'You',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: theme.colorScheme.primary,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  Text(
                                    _formatTimestamp(widget.post['createdAt']),
                                    style: TextStyle(
                                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.post['title'] ?? '',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                widget.post['content'] ?? '',
                                style: const TextStyle(
                                  fontSize: 16,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (widget.post['imageUrl'] != '')
                          Container(
                            width: double.infinity,
                            height: 300,
                            margin: const EdgeInsets.symmetric(horizontal: 16),
                            child: Image.network(
                              widget.post['imageUrl'],
                              fit: BoxFit.cover,
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Center(
                                  child: CircularProgressIndicator(
                                    value: loadingProgress.expectedTotalBytes != null
                                        ? loadingProgress.cumulativeBytesLoaded /
                                        (loadingProgress.expectedTotalBytes ?? 1)
                                        : null,
                                  ),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: isDarkMode ? Colors.grey[850] : Colors.grey[200],
                                  child: Center(
                                    child: Icon(
                                      Icons.broken_image,
                                      size: 64,
                                      color: isDarkMode ? Colors.grey[700] : Colors.grey[400],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              GestureDetector(
                                onTap: () {
                                  widget.onLike(widget.postId, widget.post);
                                },
                                child: Icon(
                                  hasUserLiked ? Icons.favorite : Icons.favorite_border,
                                  size: 20,
                                  color: hasUserLiked ? Colors.red : Colors.grey,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${widget.post['upvotes'] ?? 0} likes',
                                style: TextStyle(
                                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 5),
                          child: Divider(color: isDarkMode ? Colors.grey[800]! : Colors.grey[300]!),
                        ),
                      ],
                    ),
                  ),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('forums')
                        .doc(widget.postId)
                        .collection('comments')
                        .where('parentId', isNull: true)
                        .orderBy('createdAt', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return SliverFillRemaining(
                          child: Center(child: Text('Error: ${snapshot.error}')),
                        );
                      }

                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const SliverFillRemaining(
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }

                      final comments = snapshot.data?.docs ?? [];

                      if (comments.isEmpty) {
                        return SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.chat_bubble_outline,
                                  size: 48,
                                  color: isDarkMode ? Colors.grey[700] : Colors.grey[400],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'No comments yet. Be the first to comment!',
                                  style: TextStyle(
                                    color: isDarkMode ? Colors.grey[500] : Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      return SliverList(
                        delegate: SliverChildBuilderDelegate(
                              (context, index) {
                            final comment = comments[index].data() as Map<String, dynamic>;
                            final commentId = comments[index].id;
                            return _buildCommentWithReplies(context, comment, commentId);
                          },
                          childCount: comments.length,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            ValueListenableBuilder<String?>(
              valueListenable: replyingToId,
              builder: (context, replyId, _) {
                if (replyId != null) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDarkMode ? Colors.grey[900] : Colors.white,
                      border: Border(
                        top: BorderSide(
                          color: isDarkMode ? Colors.grey[800]! : Colors.grey[300]!,
                        ),
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            ValueListenableBuilder<String?>(
                              valueListenable: replyingToName,
                              builder: (context, name, _) => Text(
                                'Replying to ${name ?? 'comment'}',
                                style: TextStyle(
                                  fontStyle: FontStyle.italic,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.close, size: 16),
                              onPressed: () {
                                replyingToId.value = null;
                                replyingToName.value = null;
                                replyController.clear();
                                _replyImage = null;
                              },
                            ),
                          ],
                        ),
                        _buildInputField(true),
                      ],
                    ),
                  );
                }
                return Container(
                  padding: EdgeInsets.only(
                    left: 16,
                    right: 16,
                    top: 8,
                    bottom: MediaQuery.of(context).padding.bottom + 8,
                  ),
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.grey[900] : Colors.white,
                    border: Border(
                      top: BorderSide(
                        color: isDarkMode ? Colors.grey[800]! : Colors.grey[300]!,
                      ),
                    ),
                  ),
                  child: _buildInputField(false),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}