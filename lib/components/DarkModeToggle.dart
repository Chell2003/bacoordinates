import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:untitled/providers/theme_provider.dart';

class DarkModeToggle extends StatelessWidget {
  final bool showLabel;
  final bool isMini;
  
  const DarkModeToggle({
    super.key, 
    this.showLabel = true,
    this.isMini = false,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    
    return InkWell(
      onTap: () {
        themeProvider.toggleTheme();
      },
      borderRadius: BorderRadius.circular(isMini ? 8 : 12),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isMini ? 8.0 : 12.0,
          vertical: isMini ? 4.0 : 8.0,
        ),
        decoration: BoxDecoration(
          color: isDarkMode 
              ? const Color(0xFF2A2A2A) 
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(isMini ? 8 : 12),
          border: Border.all(
            color: isDarkMode ? const Color(0xFF3D3D3D) : Colors.grey.shade300,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isDarkMode ? Icons.dark_mode : Icons.light_mode,
              color: isDarkMode 
                  ? const Color(0xFFFFB74D) 
                  : const Color(0xFFFFB300),
              size: isMini ? 16 : 20,
            ),
            if (showLabel) ...[
              SizedBox(width: isMini ? 4 : 8),
              Text(
                isDarkMode ? 'Dark Mode' : 'Light Mode',
                style: TextStyle(
                  fontSize: isMini ? 11 : 13,
                  fontWeight: FontWeight.w500,
                  color: isDarkMode 
                      ? const Color(0xFFE0E0E0) 
                      : Colors.black87,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
} 