import 'package:flutter/material.dart';

class ForumCard extends StatelessWidget {
  final String authorName;
  final String authorAvatar;
  final String title;
  final String? imageUrl;
  final int upvotes;
  final int comments;
  final String time;

  const ForumCard({
    super.key,
    required this.authorName,
    required this.authorAvatar,
    required this.title,
    this.imageUrl,
    required this.upvotes,
    required this.comments,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundImage: NetworkImage(authorAvatar),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      authorName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Text(
                  time,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
            const Divider(height: 20, color: Colors.grey),
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            if (imageUrl != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(imageUrl!, fit: BoxFit.cover),
                ),
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.arrow_upward, size: 18, color: Colors.grey), // ✅ Upvote icon
                    const SizedBox(width: 5),
                    Text('$upvotes Upvotes'),
                  ],
                ),
                Row(
                  children: [
                    const Icon(Icons.comment, size: 18, color: Colors.grey),
                    const SizedBox(width: 5),
                    Text('$comments Comments'),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
