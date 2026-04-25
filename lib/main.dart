import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';

import 'providers/booking_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/splash_screen.dart';
import 'firebase_options.dart'; // ✅ IMPORTANT

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  String? firebaseError;
  bool firebaseInitialized = false;

  try {
    // ✅ Correct initialization (NO duplicate issue)
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    firebaseInitialized = true;
  } catch (e) {
    firebaseError = e.toString();
    debugPrint("Firebase initialization failed: $e");
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => BookingProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: MyApp(
        isFirebaseInitialized: firebaseInitialized,
        errorMessage: firebaseError,
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  final bool isFirebaseInitialized;
  final String? errorMessage;

  const MyApp({
    Key? key,
    required this.isFirebaseInitialized,
    this.errorMessage,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SmartSlot',
      theme: themeProvider.currentTheme,
      home: isFirebaseInitialized
          ? const SplashScreen()
          : Scaffold(
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          color: Colors.red, size: 60),
                      const SizedBox(height: 20),
                      const Text(
                        "Firebase Configuration Error",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        errorMessage ?? "Unknown initialization error.",
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
