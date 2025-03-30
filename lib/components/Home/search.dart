import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bacoordinates/providers/theme_provider.dart';

class Search extends StatelessWidget {
  const Search({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;
    
    return Container(
      padding: const EdgeInsets.all(16),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search',
          hintStyle: TextStyle(
            color: isDarkMode ? Colors.white54 : Colors.grey,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          suffixIcon: IconButton(
            icon: Icon(
              Icons.search,
              color: Theme.of(context).colorScheme.primary,
            ),
            onPressed: () {},
          ),
          filled: isDarkMode,
          fillColor: isDarkMode ? const Color(0xFF3D3F4B).withOpacity(0.7) : null,
        ),
      ),
    );
  }
}