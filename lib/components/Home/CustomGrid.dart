import 'package:flutter/material.dart';
import 'LocationWeatherCard.dart';

class CustomGrid extends StatelessWidget {
  const CustomGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(
        child: Column(
          children: [
            LocationWeatherCard(

            ),
          ],
        ),
          // flex: 2,
          // child: ItineraryCard(),
        ),
        SizedBox(width: 3),
        // Expanded(
        //   flex: 3,
        //   child: Column(
        //     children: const [
        //       LocationWeatherCard(
        //         location: 'Las Pinas',
        //         weather: 'Sunny', degree: 32,
        //       ),
        //       SizedBox(height: 3),
        //       EmergencyCallCard(),
        //     ],
        //   ),
        // ),
      ],
    );
  }
}