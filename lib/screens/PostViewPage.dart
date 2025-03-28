// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import '../providers/forum_provider.dart';
// import 'add_forum_post.dart'; // Import the post-adding page
//
// class ForumPage extends StatelessWidget {
//   const ForumPage({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Forum')),
//       body: StreamBuilder<List<Map<String, dynamic>>>(
//         stream: Provider.of<ForumService>(context, listen: false).getApprovedPosts(),
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           }
//           if (!snapshot.hasData || snapshot.data!.isEmpty) {
//             return const Center(child: Text("No approved posts yet."));
//           }
//
//           final posts = snapshot.data!;
//
//           return ListView.builder(
//             itemCount: posts.length,
//             itemBuilder: (context, index) {
//               final post = posts[index];
//
//               return Card(
//                 margin: const EdgeInsets.all(8),
//                 child: ListTile(
//                   leading: post['imageUrl'] != null && post['imageUrl'].isNotEmpty
//                       ? Image.network(post['imageUrl'], width: 50, height: 50, fit: BoxFit.cover)
//                       : const Icon(Icons.image_not_supported),
//                   title: Text(post['title']),
//                   subtitle: Text(post['content']),
//                   trailing: Column(
//                     children: [
//                       const Icon(Icons.thumb_up, size: 16),
//                       Text(post['upvotes'].toString()),
//                     ],
//                   ),
//                 ),
//               );
//             },
//           );
//         },
//       ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: () {
//           Navigator.push(
//             context,
//             MaterialPageRoute(builder: (context) => AddForumPostPage()),
//           );
//         },
//         child: const Icon(Icons.add),
//       ),
//     );
//   }
// }
