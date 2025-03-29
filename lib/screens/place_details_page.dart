import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import '../providers/theme_provider.dart';
import 'ItineraryPage.dart';

class PlaceDetailsPage extends StatelessWidget {
  final String placeId;

  const PlaceDetailsPage({super.key, required this.placeId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Place Details'),
        centerTitle: true,
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('places').doc(placeId).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildShimmerEffect();
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Place not found'));
          }

          var place = snapshot.data!;
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      place['imageUrl'],
                      width: double.infinity,
                      height: 250,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    place['title'],
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    place['description'],
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 16),
                  _buildLikesSection(place),
                  const SizedBox(height: 20),
                  _buildActionButtons(context),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLikesSection(DocumentSnapshot place) {
    return Row(
      children: [
        const Icon(Icons.favorite, color: Colors.red, size: 22),
        const SizedBox(width: 6),
        Text('${place['likes']} Likes', style: const TextStyle(fontSize: 16)),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _customButton(
          context,
          icon: Icons.schedule,
          iconColor: Colors.white, // Itinerary Icon Color
          label: 'Itinerary',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ItineraryPage(placeId: placeId),
              ),
            );
          },
        ),
        _customButton(
          context,
          icon: Icons.explore,
          iconColor: Colors.white, // Explore Icon Color
          label: 'Explore',
          onPressed: () {
            // Navigate to map
          },
        ),
      ],
    );
  }

  Widget _customButton(BuildContext context, {required IconData icon, required Color iconColor, required String label, required VoidCallback onPressed}) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: context.watch<ThemeProvider>().isDarkMode ? const Color(0xFF3D3F4B) : null,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      icon: Icon(icon, color: iconColor), // Apply Icon Color
      label: Text(label),
      onPressed: onPressed,
    );
  }

  Widget _buildShimmerEffect() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              width: double.infinity,
              height: 250,
              decoration: BoxDecoration(
                color: Colors.grey,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              width: double.infinity,
              height: 20,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              width: double.infinity,
              height: 14,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
