import 'package:flutter/material.dart';

class ThemeProvider with ChangeNotifier {
  bool _isDarkMode = false;
  bool get isDarkMode => _isDarkMode;

  ThemeData get currentTheme => _isDarkMode ? darkTheme : lightTheme;

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  static final lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: const Color(0xFF3F3D56),
    scaffoldBackgroundColor: const Color(0xFFF8F9FD),
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF3F3D56),
      secondary: Color(0xFFFFD54F),
    ),
  );

  static final darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: Colors.blueGrey,
    scaffoldBackgroundColor: const Color(0xFF121212),
    colorScheme: const ColorScheme.dark(
      primary: Colors.blueGrey,
      secondary: Color(0xFFFFD54F),
      surface: Color(0xFF1E1E1E),
    ),
  );
}
