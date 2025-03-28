import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:untitled/providers/forum_provider.dart';
import 'package:untitled/providers/theme_provider.dart';
import 'package:untitled/providers/auth_provider.dart';
import 'package:untitled/screens/HomePage.dart';
import 'package:untitled/components/StyleGuide.dart';
import 'package:untitled/screens/camera_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
        ChangeNotifierProvider(create: (context) => AuthProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return MaterialApp(
      title: 'BacoTrip',
      debugShowCheckedModeBanner: false,
      theme: themeProvider.currentTheme,
      initialRoute: '/',
      routes: {
        '/': (context) => const HomePage(),
        '/styleguide': (context) => const StyleGuide(),
        '/camera': (context) => const CameraScreen(),
      },
      builder: (context, child) {
        // Force apply theme to all child widgets
        return Theme(
          data: themeProvider.currentTheme,
          child: child!,
        );
      },
    );
  }
}
