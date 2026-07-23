import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'providers/quiz_provider.dart';
import 'services/storage_service.dart';
import 'views/dashboard_screen.dart';

void main() async {
  // Ensure Flutter framework is initialized before loading SharedPreferences
  WidgetsFlutterBinding.ensureInitialized();
  
  // Safe Firebase Initialization
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint("Firebase initialization skipped: $e");
  }
  
  // Set preferred orientations to portrait only for consistent UI layout
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system navigation/status bar styles
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    systemNavigationBarColor: Color(0xFFF8FAFC), // Cool Slate White
    systemNavigationBarIconBrightness: Brightness.dark,
  ));

  // Initialize Services
  final storageService = await StorageService.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => QuizProvider(storageService),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'منارة الهدى',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.light,
      // Define a premium light theme
      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: const Color(0xFF00AFA3), // Soft Electric Teal
        scaffoldBackgroundColor: const Color(0xFFFFFFFF), // Pure White Background
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF00AFA3),
          secondary: Color(0xFF1E3A8A), // Deep Royal Indigo
          surface: Colors.white,
          error: Color(0xFFEF4444),
        ),
        textTheme: GoogleFonts.cairoTextTheme(
          ThemeData.light().textTheme,
        ).apply(
          bodyColor: const Color(0xFF0F172A), // Rich Navy body text
          displayColor: const Color(0xFF0F172A),
        ),
      ),
      // Force RTL layout direction natively for Arabic language support
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child!,
        );
      },
      home: const DashboardScreen(),
    );
  }
}
