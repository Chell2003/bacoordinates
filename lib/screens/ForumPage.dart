import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:bacoordinates/providers/auth_provider.dart';
import 'package:bacoordinates/providers/theme_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:bacoordinates/screens/PostDetailPage.dart';

import 'PostViewPage.dart';

class ForumPage extends StatefulWidget {
  const ForumPage({super.key});

  @override
  State<ForumPage> createState() => _ForumPageState();
}

class _ForumPageState extends State<ForumPage> {
  final _postController = TextEditingController();
  final _titleController = TextEditingController();
  bool _isLoading = false;
  bool _showPostCreation = false;
  String? _selectedImageUrl;
  File? _selectedImageFile;

  // Cloudinary API Details
  final String cloudinaryUrl = "https://api.cloudinary.com/v1_1/ds8esjc0y/image/upload";
  final String uploadPreset = "flutter_upload";

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

  @override
  void dispose() {
    _postController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  Future<String?> _uploadImageToCloudinary(File imageFile) async {
    try {
      setState(() => _isLoading = true);

      var request = http.MultipartRequest("POST", Uri.parse(cloudinaryUrl));
      request.fields['upload_preset'] = uploadPreset;
      request.files.add(await http.MultipartFile.fromPath('file', imageFile.path));

      var response = await request.send();
      var responseData = await response.stream.bytesToString();
      var jsonResponse = json.decode(responseData);

      setState(() => _isLoading = false);
      return jsonResponse['secure_url']; // Returns the uploaded image URL
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading image: ${e.toString()}')),
      );
      return null;
    }
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920, // Limit max width for optimization
        maxHeight: 1080, // Limit max height for optimization
        imageQuality: 85, // Slightly compress image for better upload speed
      );

      if (image != null) {
        _selectedImageFile = File(image.path);

        // Upload to Cloudinary
        final imageUrl = await _uploadImageToCloudinary(_selectedImageFile!);

        if (imageUrl != null) {
          setState(() {
            _selectedImageUrl = imageUrl;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Image uploaded successfully!')),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error selecting image: ${e.toString()}')),
      );
    }
  }

  Future<void> _createPost() async {
    final title = _titleController.text.trim();
    final content = _postController.text.trim();

    print('Attempting to create post:');
    print('Title: $title');
    print('Content: $content');
    print('Image URL: $_selectedImageUrl');

    if (title.isEmpty || content.isEmpty) {
      print('Title or content is empty');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in both title and content')),
      );
      return;
    }

    setState(() {
      print('Setting loading state to true');
      _isLoading = true;
    });

    try {
      final user = context.read<AuthProvider>().user;
      if (user == null) {
        print('User is not authenticated');
        throw Exception('User not authenticated');
      }

      // Get username from Firestore
      String? username = await _getUserName(user.uid);

      print('Creating post in Firestore');
      await FirebaseFirestore.instance.collection('forums').add({
        'title': title,
        'content': content,
        'authorId': user.uid,
        'authorName': username ?? 'Anonymous',
        'authorAvatar': user.photoURL,
        'createdAt': FieldValue.serverTimestamp(),
        'upvotes': 0,
        'comments': 0,
        'status': 'Pending',
        'imageUrl': _selectedImageUrl ?? '',
        'likedBy': [],
      });

      print('Post created successfully');
      _titleController.clear();
      _postController.clear();
      setState(() {
        _showPostCreation = false;
        _selectedImageUrl = null;
        _selectedImageFile = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post created and pending approval!')),
      );
    } catch (e) {
      print('Error creating post: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating post: ${e.toString()}')),
      );
    } finally {
      setState(() {
        print('Setting loading state to false');
        _isLoading = false;
      });
    }
  }

  Future<void> _handleLike(String postId, Map<String, dynamic> post) async {
    try {
      final user = context.read<AuthProvider>().user;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You need to sign in to like posts')),
        );
        return;
      }

      // Get a reference to the post
      final postRef = FirebaseFirestore.instance.collection('forums').doc(postId);

      try {
        // Check if the post has a likedBy field
        List<dynamic> likedBy = post['likedBy'] ?? [];

        // Convert to List<String> if it exists
        List<String> likedByIds = likedBy.map((e) => e.toString()).toList();

        // Check if user already liked this post
        bool userLiked = likedByIds.contains(user.uid);

        if (userLiked) {
          // User already liked this post, so unlike it (remove from list and decrement count)
          await postRef.update({
            'upvotes': FieldValue.increment(-1),
            'likedBy': FieldValue.arrayRemove([user.uid]),
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Post unliked'),
              duration: Duration(seconds: 1),
            ),
          );
        } else {
          // User has not liked this post yet, so like it (add to list and increment count)
          await postRef.update({
            'upvotes': FieldValue.increment(1),
            'likedBy': FieldValue.arrayUnion([user.uid]),
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Post liked!'),
              duration: Duration(seconds: 1),
            ),
          );
        }

      } catch (e) {
        if (e.toString().contains('permission-denied')) {
          // Permission issue - show helpful message to the user
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Cannot Like Post'),
              content: const Text(
                'Your current permissions do not allow liking posts. Please ask an administrator to update the Firestore rules to allow updates to the "upvotes" and "likedBy" fields by regular users.\n\n'
                'Suggested rule to add:\n\n'
                'allow update: if request.auth != null &&\n'
                '  request.resource.data.diff(resource.data).affectedKeys().hasOnly([\'upvotes\', \'likedBy\']) &&\n'
                '  (request.resource.data.upvotes == resource.data.upvotes + 1 ||\n'
                '   request.resource.data.upvotes == resource.data.upvotes - 1);'
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        } else {
          // Other errors
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error liking post: ${e.toString()}')),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error processing like: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Community',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : Theme.of(context).colorScheme.primary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // Implement search
            },
          ),
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () {
              // Implement notifications
            },
          ),
        ],
        elevation: 0,
      ),
      body: Column(
        children: [
          // Create post compact bar
          if (!_showPostCreation)
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: () {
                  setState(() {
                    _showPostCreation = true;
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                        backgroundImage: user?.photoURL != null
                            ? NetworkImage(user!.photoURL!) as ImageProvider
                            : null,
                        child: user?.photoURL == null && user != null
                            ? FutureBuilder<String?>(
                                future: _getUserName(user.uid),
                                builder: (context, snapshot) {
                                  final username = snapshot.data;
                                  return Text(
                                    username != null && username.isNotEmpty ? username[0].toUpperCase() : 'A',
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  );
                                },
                              )
                            : null,
                      ),
                      const SizedBox(width: 12),
                Expanded(
                        child: Text(
                          'What\'s on your mind?',
                          style: TextStyle(
                            color: isDarkMode ? Colors.white70 : Colors.grey[600],
                          ),
                        ),
                      ),
                      Icon(
                        Icons.photo_library_outlined,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Post Creation Card
          if (_showPostCreation)
            Card(
              // margin: const EdgeInsets.all(12),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                              backgroundImage: user?.photoURL != null
                                  ? NetworkImage(user!.photoURL!) as ImageProvider
                                  : null,
                              child: user?.photoURL == null && user != null
                                  ? FutureBuilder<String?>(
                                      future: _getUserName(user.uid),
                                      builder: (context, snapshot) {
                                        final username = snapshot.data;
                                        return Text(
                                          username != null && username.isNotEmpty ? username[0].toUpperCase() : 'A',
                                          style: TextStyle(
                                            color: Theme.of(context).colorScheme.primary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        );
                                      },
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            if (user != null)
                              FutureBuilder<String?>(
                                future: _getUserName(user.uid),
                                builder: (context, snapshot) {
                                  final username = snapshot.data;
                                  return Text(
                                    username != null && username.isNotEmpty ? username : '',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  );
                                },
                              ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            setState(() {
                              _showPostCreation = false;
                              _titleController.clear();
                              _postController.clear();
                            });
                          },
                        ),
                      ],
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: TextField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        hintText: 'What is this discussion',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        hintStyle: TextStyle(
                          color: isDarkMode ? Colors.white60 : Colors.grey[500],
                        ),
                      ),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                  // Post Creation Card content area
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Column(
                      children: [
                        TextField(
                    controller: _postController,
                          decoration: InputDecoration(
                            hintText: 'What\'s on your mind?',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            hintStyle: TextStyle(
                              color: isDarkMode ? Colors.white60 : Colors.grey[500],
                            ),
                          ),
                          style: const TextStyle(
                            fontSize: 16,
                            height: 1.3,
                          ),
                          maxLines: 6,
                          minLines: 3,
                        ),
                        if (_selectedImageUrl != null) ...[
                          const SizedBox(height: 16),
                          Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  _selectedImageUrl!,
                                  height: 200,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.5),
                                    shape: BoxShape.circle,
                                  ),
                                  child: IconButton(
                                    icon: const Icon(Icons.close, color: Colors.white),
                                    onPressed: () {
                                      setState(() {
                                        _selectedImageUrl = null;
                                      });
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),

                  Container(
                    height: 52,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: isDarkMode ? Colors.grey[900] : Colors.grey[100],
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(16),
                        bottomRight: Radius.circular(16),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              _mediaButton(
                                icon: Icons.photo,
                                label: 'Photo',
                                color: Colors.green,
                                onTap: _pickImage,
                              ),
                            ],
                          ),
                        ),
                        Material(
                          color: _titleController.text.trim().isNotEmpty && _postController.text.trim().isNotEmpty
                              ? Theme.of(context).colorScheme.primary
                              : isDarkMode ? Colors.grey[800] : Colors.grey[300],
                          borderRadius: BorderRadius.circular(24),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(24),
                            onTap: () {
                              if (_isLoading) {
                                return;
                              }
                              if (_titleController.text.trim().isEmpty || _postController.text.trim().isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Please fill in both title and content')),
                                );
                                return;
                              }
                              _createPost();
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.white,
                                        ),
                                      ),
                                    )
                                  : Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'Post',
                                          style: TextStyle(
                                            color: _titleController.text.trim().isNotEmpty && _postController.text.trim().isNotEmpty
                                                ? Colors.white
                                                : isDarkMode ? Colors.grey[600] : Colors.grey[500],
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        if (_titleController.text.trim().isNotEmpty && _postController.text.trim().isNotEmpty) ...[
                                          const SizedBox(width: 4),
                                          const Icon(
                                            Icons.send,
                                            size: 16,
                                            color: Colors.white,
                                          ),
                                        ],
                                      ],
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                ),
              ],
            ),
          ),

          // Posts List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('forums')
                  .where('status', isEqualTo: 'Approved')
                  .orderBy('createdAt', descending: true)
                  .orderBy(FieldPath.documentId, descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  // Show a more user-friendly error message for permission errors
                  if (snapshot.error.toString().contains('permission-denied')) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.lock_outline,
                            size: 64,
                            color: isDarkMode ? Colors.white30 : Colors.grey[300],
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Unable to access posts',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32),
                            child: Text(
                              'You may need to sign in or request access to view this content.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: isDarkMode ? Colors.white70 : Colors.grey[600],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  );
                }

                final forums = snapshot.data?.docs ?? [];

                if (forums.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.forum_outlined,
                          size: 64,
                          color: isDarkMode ? Colors.white30 : Colors.grey[300],
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No posts yet. Be the first to share!',
                          style: TextStyle(
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: forums.length,
                  padding: const EdgeInsets.only(bottom: 16),
                  itemBuilder: (context, index) {
                    final post = forums[index].data() as Map<String, dynamic>;
                    final postId = forums[index].id;

                    return ForumCard(
                      post: post,
                      postId: postId,
                      onLike: () {
                        _handleLike(postId, post);
                      },
                      onShare: () {
                        // Implement share functionality
                      },
                      onMoreOptions: () {
                        // Show post options
                        final isUserPost = post['authorId'] == context.read<AuthProvider>().user?.uid;
                        showModalBottomSheet(
                          context: context,
                          builder: (context) => Column(
                            mainAxisSize: MainAxisSize.min,
                          children: [
                              if (isUserPost)
                                ListTile(
                                  leading: const Icon(Icons.edit),
                                  title: const Text('Edit Post'),
                                  onTap: () {
                                    Navigator.pop(context);
                                    _showEditPostDialog(context, postId, post);
                                  },
                                ),
                              if (isUserPost)
                                ListTile(
                                  leading: const Icon(Icons.delete, color: Colors.red),
                                  title: const Text('Delete Post', style: TextStyle(color: Colors.red)),
                                  onTap: () {
                                    Navigator.pop(context);
                                    _showDeleteConfirmation(context, postId, post);
                                  },
                                ),
                              if (!isUserPost)
                                ListTile(
                                  leading: const Icon(Icons.report),
                                  title: const Text('Report Post'),
                                  onTap: () {
                                    Navigator.pop(context);
                                    // Implement report
                                  },
                                ),
                            //   ListTile(
                            //     leading: const Icon(Icons.share),
                            //     title: const Text('Share Post'),
                            //     onTap: () {
                            //       Navigator.pop(context);
                            //       // Implement share
                            //     },
                            // ),
                          ],
                        ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: _showPostCreation ? null : FloatingActionButton(
        onPressed: () {
          setState(() {
            _showPostCreation = true;
          });
        },
        mini: true,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _mediaButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
                      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 18,
                color: color,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: isDarkMode ? Colors.white70 : Colors.grey[800],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditPostDialog(BuildContext context, String postId, Map<String, dynamic> post) {
    final TextEditingController titleController = TextEditingController(text: post['title']);
    final TextEditingController contentController = TextEditingController(text: post['content']);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Post'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                hintText: 'Enter post title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: contentController,
              decoration: const InputDecoration(
                labelText: 'Content',
                hintText: 'Update your post content...',
                border: OutlineInputBorder(),
              ),
              maxLines: 5,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (titleController.text.trim().isEmpty || contentController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Title and content cannot be empty')),
                );
                return;
              }

              _updatePost(postId, titleController.text.trim(), contentController.text.trim());
              Navigator.pop(context);
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  Future<void> _updatePost(String postId, String newTitle, String newContent) async {
    try {
      await FirebaseFirestore.instance.collection('forums').doc(postId).update({
        'title': newTitle,
        'content': newContent,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Post updated successfully!'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating post: ${e.toString()}')),
      );
    }
  }

  void _showDeleteConfirmation(BuildContext context, String postId, Map<String, dynamic> post) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Post'),
        content: const Text('Are you sure you want to delete this post? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            onPressed: () {
              _deletePost(postId);
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deletePost(String postId) async {
    try {
      await FirebaseFirestore.instance.collection('forums').doc(postId).delete();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Post deleted successfully!'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting post: ${e.toString()}')),
      );
    }
  }
}

class ForumCard extends StatelessWidget {
  final Map<String, dynamic> post;
  final String postId;
  final VoidCallback onLike;
  final VoidCallback onShare;
  final VoidCallback onMoreOptions;

  const ForumCard({
    super.key,
    required this.post,
    required this.postId,
    required this.onLike,
    required this.onShare,
    required this.onMoreOptions,
  });

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

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return '';
    final date = timestamp.toDate();
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

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;
    final hasImage = post['imageUrl'] != null && post['imageUrl'].toString().isNotEmpty;
    final theme = Theme.of(context);
    final isUserPost = post['authorId'] == context.read<AuthProvider>().user?.uid;

    // Check if current user has liked this post
    final user = context.read<AuthProvider>().user;
    final List<dynamic> likedBy = post['likedBy'] ?? [];
    final bool hasUserLiked = user != null && likedBy.contains(user.uid);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(5),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PostDetailPage(
                post: post,
                postId: postId,
                onLike: (String id, Map<String, dynamic> updatedPost) => onLike(),
              ),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Author info and timestamp
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundImage: post['authorAvatar'] != null && post['authorAvatar'].toString().isNotEmpty
                        ? NetworkImage(post['authorAvatar'])
                        : null,
                    backgroundColor: post['authorAvatar'] == null || post['authorAvatar'].toString().isEmpty
                        ? theme.colorScheme.primary.withValues(alpha: 0.1)
                        : null,
                    child: post['authorAvatar'] == null || post['authorAvatar'].toString().isEmpty
                        ? Text(
                            post['authorName'] != null && post['authorName'].toString().isNotEmpty
                                ? post['authorName'].toString()[0].toUpperCase()
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
                            post['authorName'] != null && post['authorName'].toString().isNotEmpty
                                ? Text(
                              post['authorName'].toString(),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            )
                                : FutureBuilder<String?>(
                              future: _getUserName(post['authorId']),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState == ConnectionState.waiting) {
                                  return const SizedBox(
                                    width: 50,
                                    height: 15,
                                    child: LinearProgressIndicator(),
                                  );
                                }
                                final username = snapshot.data ?? 'Unknown';
                                return Text(
                                  username,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                );
                              },
                            ),
                            if (isUserPost) ...[
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'You',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        Text(
                          _formatTimestamp(post['createdAt']),
                          style: TextStyle(
                            fontSize: 13,
                            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.more_horiz,
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
                    ),
                    onPressed: onMoreOptions,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    splashRadius: 24,
                  ),
                ],
              ),
            ),

            // Title
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Text(
                post['title'] ?? '',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // Image if exists
            if (hasImage)
              SizedBox(
                width: double.infinity,
                height: 200,
                child: Image.network(
                  post['imageUrl'],
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: isDarkMode ? Colors.grey[850] : Colors.grey[200],
                      child: Icon(
                        Icons.broken_image,
                        size: 64,
                        color: isDarkMode ? Colors.grey[700] : Colors.grey[400],
                      ),
                    );
                  },
                ),
              ),

            // Engagement stats
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    hasUserLiked ? Icons.favorite : Icons.favorite_border,
                    size: 16,
                    color: hasUserLiked ? Colors.red : (isDarkMode ? Colors.grey[400] : Colors.grey[600]),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${post['upvotes'] ?? 0}',
                    style: TextStyle(
                      color: hasUserLiked ? Colors.red : (isDarkMode ? Colors.grey[400] : Colors.grey[600]),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 16,
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${post['comments'] ?? 0}',
                    style: TextStyle(
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),

            // Add divider
            Divider(
              height: 0.5,
              thickness: 0.5,
              color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isActive,
    required bool isDarkMode,
    required Color activeColor,
  }) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: isActive
                      ? activeColor
                      : isDarkMode ? Colors.grey[400] : Colors.grey[700],
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: isActive
                        ? activeColor
                        : isDarkMode ? Colors.grey[400] : Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
