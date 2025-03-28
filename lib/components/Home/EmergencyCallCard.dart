import 'package:flutter/material.dart';

class EmergencyCallCard extends StatelessWidget {
  const EmergencyCallCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.red,
      child: Container(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  width: 2,
                  color: Colors.white.withOpacity(0.5),
                ),
              ),
              child: Icon(
                Icons.phone_in_talk,
                size: 30,
                color: Colors.white.withOpacity(0.5),
              ),
            ),
            const SizedBox(
              width: 10,
            ),
            Text(
              'Emergency Call',
              style: TextStyle(
                fontSize: MediaQuery.of(context).size.width * 0.05,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}