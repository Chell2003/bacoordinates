import 'package:flutter/material.dart';

class NavBarPlaces extends StatefulWidget {
  final Function(int) onCategorySelected; // Callback to notify parent

  const NavBarPlaces({super.key, required this.onCategorySelected});

  @override
  _NavBarPlacesState createState() => _NavBarPlacesState();
}

class _NavBarPlacesState extends State<NavBarPlaces> {
  int selectedIndex = 0; // Track selected category

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavItem('Popular', 0),
          _buildNavItem('Historical', 1),
          _buildNavItem('Restaurant', 2),
          _buildNavItem('Hotel', 3),
        ],
      ),
    );
  }

  Widget _buildNavItem(String label, int index) {
    final isSelected = index == selectedIndex;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedIndex = index;
        });
        widget.onCategorySelected(index); // Notify parent
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
        decoration: isSelected
            ? const BoxDecoration(
          border: Border(
            bottom: BorderSide(
              width: 2,
              color: Colors.yellow,
            ),
          ),
        )
            : null,
        child: Text(
          label,
          style: TextStyle(
            color: Colors.black,
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}