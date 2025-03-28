import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  static const String _themeKey = 'isDarkMode';
  bool _isDarkMode = false;

  ThemeProvider() {
    _loadTheme();
  }

  bool get isDarkMode => _isDarkMode;

  ThemeData get currentTheme => _isDarkMode 
    ? ThemeData.dark().copyWith(
        primaryColor: const Color(0xFF2D2F3E),
        scaffoldBackgroundColor: const Color(0xFF121212),
        cardColor: const Color(0xFF1E1E1E),
        canvasColor: const Color(0xFF121212),
        dialogBackgroundColor: const Color(0xFF1E1E1E),
        dividerColor: const Color(0xFF3D3D3D),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF4080FF), // Softer blue for dark mode
          secondary: Color(0xFFFFB74D), // Softer amber
          tertiary: Color(0xFFFFB74D), // Matching amber
          surface: Color(0xFF1E1E1E),
          error: Color(0xFFCF6679), // Softer error color
          onPrimary: Colors.white,
          onSecondary: Colors.black,
          onSurface: Color(0xFFE0E0E0),
          onError: Colors.black,
          brightness: Brightness.dark,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E1E1E),
          foregroundColor: Color(0xFFE0E0E0),
          elevation: 0,
          iconTheme: IconThemeData(color: Color(0xFFE0E0E0)),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4080FF),
            foregroundColor: Colors.white,
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFF4080FF),
          foregroundColor: Colors.white,
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Color(0xFFE0E0E0)),
          bodyMedium: TextStyle(color: Color(0xFFE0E0E0)),
          titleLarge: TextStyle(color: Color(0xFFE0E0E0)),
          titleMedium: TextStyle(color: Color(0xFFE0E0E0)),
          titleSmall: TextStyle(color: Color(0xFFE0E0E0)),
          displayLarge: TextStyle(color: Color(0xFFE0E0E0)),
          displayMedium: TextStyle(color: Color(0xFFE0E0E0)),
          displaySmall: TextStyle(color: Color(0xFFE0E0E0)),
          headlineLarge: TextStyle(color: Color(0xFFE0E0E0)),
          headlineMedium: TextStyle(color: Color(0xFFE0E0E0)),
          headlineSmall: TextStyle(color: Color(0xFFE0E0E0)),
          labelLarge: TextStyle(color: Color(0xFFE0E0E0)),
          labelMedium: TextStyle(color: Color(0xFFE0E0E0)),
          labelSmall: TextStyle(color: Color(0xFFE0E0E0)),
        ),
        iconTheme: const IconThemeData(color: Color(0xFFE0E0E0)),
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith<Color>((states) {
            if (states.contains(WidgetState.selected)) {
              return const Color(0xFFFFB74D);
            }
            return const Color(0xFFE0E0E0);
          }),
          trackColor: WidgetStateProperty.resolveWith<Color>((states) {
            if (states.contains(WidgetState.selected)) {
              return const Color(0xFFFFB74D).withOpacity(0.5);
            }
            return Colors.grey.withOpacity(0.3);
          }),
        ),
        listTileTheme: const ListTileThemeData(
          textColor: Color(0xFFE0E0E0),
          iconColor: Color(0xFFE0E0E0),
        ),
        inputDecorationTheme: InputDecorationTheme(
          labelStyle: const TextStyle(color: Color(0xFFB0B0B0)),
          hintStyle: const TextStyle(color: Color(0xFF909090)),
          fillColor: const Color(0xFF2A2A2A),
          filled: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF3D3D3D)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF3D3D3D)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF4080FF)),
          ),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color(0xFF1E1E1E),
          selectedItemColor: Color(0xFF4080FF),
          unselectedItemColor: Color(0xFF909090),
        ),
      ) 
    : ThemeData.light().copyWith(
        primaryColor: Colors.blue,
        scaffoldBackgroundColor: Colors.white,
        cardColor: Colors.white,
        colorScheme: const ColorScheme.light(
          primary: Colors.blue,
          secondary: Colors.yellow,
          tertiary: Color(0xFFFFB300), // yellow[700]
          surface: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.blue,
          elevation: 2,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
        inputDecorationTheme: InputDecorationTheme(
          labelStyle: const TextStyle(color: Colors.blue),
          hintStyle: TextStyle(color: Colors.grey.shade600),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.blue),
          ),
        ),
      );

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool(_themeKey) ?? false;
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeKey, _isDarkMode);
    notifyListeners();
  }
} 