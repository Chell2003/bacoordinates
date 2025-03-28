import 'package:flutter/material.dart';

class TabbedProfileComponent extends StatelessWidget {
  const TabbedProfileComponent({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          const TabBar(
            labelColor: Colors.blueAccent,
            unselectedLabelColor: Colors.black54,
            indicatorColor: Colors.blueAccent,
            tabs: [
              Tab(icon: Icon(Icons.favorite_border_rounded), text: 'Favorites'),
              Tab(icon: Icon(Icons.forum_rounded), text: 'Forum'),
              Tab(icon: Icon(Icons.history_rounded), text: 'History'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                // Favorite Places Tab
                _buildTabContent(
                  title: "Favorite Places",
                  content: ["Paris, France", "New York, USA"],
                ),

                // Forum Tab
                _buildTabContent(
                  title: "Forum Posts",
                  content: [
                    "1. How to visit France?",
                    "2. Best travel tips for solo travelers"
                  ],
                ),

                // Travel History Tab
                _buildTabContent(
                  title: "Travel History",
                  content: [
                    "1. Paris, France - 2022",
                    "2. Rome, Italy - 2021"
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent({required String title, required List<String> content}) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          for (var item in content)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Text(item, style: const TextStyle(fontSize: 16)),
            ),
        ],
      ),
    );
  }
}