import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CreateForum extends StatefulWidget {
  const CreateForum({super.key});

  @override
  _CreateForumState createState() => _CreateForumState();
}

class _CreateForumState extends State<CreateForum> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  File? _image;
  bool _isLoading = false;

  // Cloudinary API Details (Replace with your own)
  final String cloudinaryUrl = "https://api.cloudinary.com/v1_1/ds8esjc0y/image/upload";
  final String uploadPreset = "flutter_upload"; // Set this in Cloudinary Settings

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<String?> _uploadImageToCloudinary(File imageFile) async {
    try {
      var request = http.MultipartRequest("POST", Uri.parse(cloudinaryUrl));
      request.fields['upload_preset'] = uploadPreset;
      request.files.add(await http.MultipartFile.fromPath('file', imageFile.path));

      var response = await request.send();
      var responseData = await response.stream.bytesToString();
      var jsonResponse = json.decode(responseData);

      return jsonResponse['secure_url']; // Returns the uploaded image URL
    } catch (e) {
      print("Error uploading image: $e");
      return null;
    }
  }

  Future<void> _submitForum() async {
    String title = _titleController.text.trim();
    String content = _contentController.text.trim();

    if (title.isEmpty || content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Title and content cannot be empty!")),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Get the currently logged-in user
    User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You must be logged in to create a forum.")),
      );
      setState(() => _isLoading = false);
      return;
    }

    String? imageUrl;
    if (_image != null) {
      imageUrl = await _uploadImageToCloudinary(_image!);
    }

    // Save forum to Firestore with author details
    await FirebaseFirestore.instance.collection('forums').add({
      'title': title,
      'content': content,
      'imageUrl': imageUrl ?? '',
      'upvotes': 0,
      'comments': 0,
      'createdAt': Timestamp.now(),
      'authorId': user.uid,
      'status': 'Pending',
      'authorName': user.displayName ?? 'Anonymous', // Get user name
      'authorAvatar': user.photoURL ?? '', // Get profile picture
    });

    setState(() {
      _titleController.clear();
      _contentController.clear();
      _image = null;
      _isLoading = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Forum submitted for review!")),
    );

    Navigator.pop(context); // Go back to the previous screen after posting
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Create a New Forum")),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ListView(
            children: [
              const Text(
                'Create a New Discussion',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.grey[100],
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _contentController,
                maxLines: 5,
                decoration: InputDecoration(
                  labelText: 'Content',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.grey[100],
                ),
              ),
              const SizedBox(height: 12),
              if (_image != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    _image!,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.upload),
                label: const Text('Upload Image'),
              ),
              const SizedBox(height: 20),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                onPressed: _submitForum,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  textStyle: const TextStyle(fontSize: 16),
                ),
                child: const Text("Post Forum"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
