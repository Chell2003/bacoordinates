import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

class ForumService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String cloudinaryUrl =
      "https://api.cloudinary.com/v1_1/ds8esjc0y/image/upload";

  /// Fetch only approved forum posts
  Stream<List<Map<String, dynamic>>> getApprovedPosts() {
    return _firestore
        .collection('forum')
        .where('status', isEqualTo: 'Approved')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  /// Upload image to Cloudinary
  Future<String?> uploadImage(File imageFile) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse(cloudinaryUrl));
      request.fields['upload_preset'] = 'your_upload_preset'; // Set Cloudinary preset
      request.files.add(await http.MultipartFile.fromPath('file', imageFile.path));

      var response = await request.send();
      var responseData = await response.stream.bytesToString();
      var decodedData = jsonDecode(responseData);

      return decodedData['secure_url']; // Return uploaded image URL
    } catch (e) {
      print('Image upload failed: $e');
      return null;
    }
  }

  /// Add a new forum post
  Future<void> addPost({
    required String title,
    required String content,
    required String authorId,
    required String authorName,
    File? imageFile,
  }) async {
    try {
      String? imageUrl;
      if (imageFile != null) {
        imageUrl = await uploadImage(imageFile);
      }

      await _firestore.collection('forum').add({
        'title': title,
        'content': content,
        'authorId': authorId,
        'authorName': authorName,
        'imageUrl': imageUrl ?? '',
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'Pending', // New posts require admin approval
        'upvotes': 0,
        'comments': 0,
      });
    } catch (e) {
      print('Error adding post: $e');
    }
  }
}
