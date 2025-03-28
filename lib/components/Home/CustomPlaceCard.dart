import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class CustomPlaceCard extends StatefulWidget {
  final String placeId; // Firestore document ID
  final String imageUrl;
  final String title;
  final String description;
  final String category;
  final int likes;
  final List<String> likedBy; // List of user IDs who liked

  const CustomPlaceCard({
    super.key,
    required this.placeId,
    required this.imageUrl,
    required this.title,
    required this.description,
    required this.category,
    required this.likes,
    required this.likedBy,
  });

  @override
  _CustomPlaceCardState createState() => _CustomPlaceCardState();
}

class _CustomPlaceCardState extends State<CustomPlaceCard> {
  late int likeCount;
  late bool isLiked;
  final String userId = FirebaseAuth.instance.currentUser!.uid; // Get current user ID

  @override
  void initState() {
    super.initState();
    likeCount = widget.likes;
    isLiked = widget.likedBy.contains(userId);
  }

  void toggleLike() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You need to sign in to like this place')),
      );
      return;
    }

    final String userId = user.uid;
    final docRef = FirebaseFirestore.instance.collection('places').doc(widget.placeId);

    try {
      // Fetch the current document data
      final docSnapshot = await docRef.get();
      if (!docSnapshot.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('This place does not exist')),
        );
        return;
      }

      final data = docSnapshot.data() as Map<String, dynamic>;

      // Ensure 'likedBy' exists and is a list
      List<dynamic> likedBy = data['likedBy'] ?? [];
      List<String> likedByIds = likedBy.map((e) => e.toString()).toList();

      bool userLiked = likedByIds.contains(userId);

      // Toggle like state
      setState(() {
        isLiked = !userLiked;
        likeCount += isLiked ? 1 : -1;
      });

      // Perform Firestore update
      if (userLiked) {
        // Unlike: remove user ID and decrement like count
        await docRef.update({
          'likes': FieldValue.increment(-1),
          'likedBy': FieldValue.arrayRemove([userId])
        });

        // ScaffoldMessenger.of(context).showSnackBar(
        //   const SnackBar(content: Text('Like removed'), duration: Duration(seconds: 1)),
        // );
      } else {
        // Like: add user ID and increment like count
        await docRef.update({
          'likes': FieldValue.increment(1),
          'likedBy': FieldValue.arrayUnion([userId])
        });

        // ScaffoldMessenger.of(context).showSnackBar(
        //   const SnackBar(content: Text('Place liked!'), duration: Duration(seconds: 1)),
        // );
      }

    } catch (e) {
      print("Firestore Error: $e"); // Debugging output

      if (e.toString().contains('permission-denied')) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Cannot Like Place'),
            content: Text(
              'Your current permissions do not allow liking/unliking places. Error details: \n\n$e\n\n'
                  'Please update Firestore rules to allow users to modify the "likes" and "likedBy" fields.',
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating like: ${e.toString()}')),
        );
      }
    }
  }



  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(15),
              topRight: Radius.circular(15),
            ),
            child: Stack(
              children: [
                Image.network(
                  widget.imageUrl,
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: GestureDetector(
                    onTap: toggleLike,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isLiked ? Icons.favorite : Icons.favorite_border,
                        color: Colors.red,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  widget.description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 10, right: 10, left: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.favorite, color: Colors.red, size: 18),
                    const SizedBox(width: 5),
                    Text('$likeCount Likes'),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.map,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
