import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:untitled/providers/language_provider.dart';
import 'package:untitled/providers/theme_provider.dart';
import 'package:untitled/providers/auth_provider.dart';
import 'package:untitled/screens/LoginPage.dart';
import 'package:untitled/screens/HomePage.dart';
import 'package:untitled/components/StyleGuide.dart';
import 'package:untitled/screens/camera_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:untitled/l10n/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: Consumer3<ThemeProvider, LanguageProvider, AuthProvider>(
        builder: (context, themeProvider, languageProvider, authProvider, child) {
          return MaterialApp(
            title: 'Travel App',
            theme: ThemeData(
              primarySwatch: Colors.blue,
              brightness: themeProvider.isDarkMode ? Brightness.dark : Brightness.light,
            ),
            locale: languageProvider.currentLocale,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('en'),
              Locale('es'),
            ],
            home: authProvider.user != null ? const HomePage() : const LoginPage(),
          );
        },
      ),
    );
  }
}