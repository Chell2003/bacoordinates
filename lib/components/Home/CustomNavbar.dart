import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:untitled/providers/theme_provider.dart';

class CustomNavbar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;

  const CustomNavbar({super.key, required this.selectedIndex, required this.onItemTapped});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;
    
    return Container(
      height: 60, // Set the height
      margin: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF3D3F4B) : Colors.blue[700],
        borderRadius: BorderRadius.circular(50), // Rounded edges
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavItem(context, FontAwesomeIcons.language, 'Translator', 0),
          _buildNavItem(context, FontAwesomeIcons.camera, 'Camera', 1),
          _buildNavItem(context, FontAwesomeIcons.home, 'Home', 2),
          _buildNavItem(context, FontAwesomeIcons.solidComments, 'Forum', 3),
          _buildNavItem(context, FontAwesomeIcons.solidUser, 'User', 4),
        ],
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, IconData icon, String label, int index) {
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;
    final accentColor = isDarkMode 
        ? const Color(0xFFFFB300) // yellow[700] in dark mode
        : Colors.white;
    final inactiveColor = isDarkMode
        ? Colors.white70
        : Colors.white70;
        
    return IconButton(
      icon: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: selectedIndex == index ? accentColor : inactiveColor,
            size: 20,
          ),
          if (selectedIndex == index)
            Text(
              label,
              style: TextStyle(
                color: accentColor,
                fontSize: 12,
              ),
            ),
        ],
      ),
      onPressed: () {
        if (index == 2) {
          // If home button is pressed, navigate to HomeScreen
          onItemTapped(2);
        } else {
          onItemTapped(index);
        }
      },
      alignment: Alignment.center,
    );
  }
}