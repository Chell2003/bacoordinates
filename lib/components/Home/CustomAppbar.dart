import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bacoordinates/providers/theme_provider.dart';

class CustomAppBarExample extends StatelessWidget implements PreferredSizeWidget {
  const CustomAppBarExample({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;
    
    return AppBar(
      backgroundColor: isDarkMode ? const Color(0xFF3D3F4B) : Colors.white,
      elevation: 2,
      title: RichText(
        text: TextSpan(
          children: [
            const TextSpan(
              text: 'BACOOR',
              style: TextStyle(
                color: Color(0xFFFFB300), // yellow[700]
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            TextSpan(
              text: 'DINATES',
              style: TextStyle(
                color: isDarkMode ? Colors.white : Colors.blue,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}