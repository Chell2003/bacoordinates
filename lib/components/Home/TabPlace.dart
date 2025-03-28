import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'CustomPlaceCard.dart';

class TabPlace extends StatefulWidget {
  const TabPlace({super.key});

  @override
  _TabPlaceState createState() => _TabPlaceState();
}

class _TabPlaceState extends State<TabPlace> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          TabBar(
            isScrollable: true,
            controller: _tabController,
            labelColor: Theme.of(context).colorScheme.primary,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Theme.of(context).colorScheme.primary,
            tabs: const [
              Tab(text: 'Popular'),
              Tab(text: 'Churches'),
              Tab(text: 'Historical'),
              Tab(text: 'Restaurants'),
              Tab(text: 'Hotels'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildPopularList(), // Fetches places with likes > 0
                _buildCategoryList('Churches'),
                _buildCategoryList('Historical'),
                _buildCategoryList('Restaurants'),
                _buildCategoryList('Hotels'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// ✅ Fetches only places that have at least 1 like (for the Popular tab)
  Widget _buildPopularList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('places')
          .where('likes', isGreaterThan: 0) // Only show places with likes > 0
          .orderBy('likes', descending: true) // Show most liked places first
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No popular places yet!'));
        }

        var places = snapshot.data!.docs;

        return ListView.builder(
          itemCount: places.length,
          itemBuilder: (context, index) {
            var place = places[index];
            return CustomPlaceCard(
              placeId: place.id,
              imageUrl: place['imageUrl'] ?? '',
              title: place['title'] ?? 'No Title',
              description: place['description'] ?? 'No Description',
              category: place['category'] ?? '',
              likes: place['likes'] ?? 0,
              likedBy: List<String>.from(place['likedBy'] ?? []),
            );
          },
        );
      },
    );
  }

  /// ✅ Fetches places by category (for Churches, Historical, etc.)
  Widget _buildCategoryList(String category) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('places')
          .where('category', isEqualTo: category) // Show places matching category
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text('No places found in $category'));
        }

        var places = snapshot.data!.docs;

        return ListView.builder(
          itemCount: places.length,
          itemBuilder: (context, index) {
            var place = places[index];
            return CustomPlaceCard(
              placeId: place.id,
              imageUrl: place['imageUrl'] ?? '',
              title: place['title'] ?? 'No Title',
              description: place['description'] ?? 'No Description',
              category: place['category'] ?? '',
              likes: place['likes'] ?? 0,
              likedBy: List<String>.from(place['likedBy'] ?? []),
            );
          },
        );
      },
    );
  }
}
