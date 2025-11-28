import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData lightTheme = ThemeData(
      fontFamily: 'Poppins',
      colorScheme: ColorScheme(
          brightness: Brightness.light,
          primary: Color.fromRGBO(24, 192, 193, 1).withOpacity(0.7),
          onPrimary: Colors.white,
          secondary: Color.fromRGBO(255, 146, 90, 1),
          onSecondary: Color.fromRGBO(0, 0, 0, 0.4),
          error: Colors.redAccent,
          onError: Colors.white,
          surface: Colors.white,
          onSurface: Color.fromRGBO(84, 106, 131, 1),
          secondaryContainer: Color.fromRGBO(24, 192, 193, 0.25)),
      scaffoldBackgroundColor: Color.fromRGBO(242, 245, 250, 1),
      textTheme: TextTheme(
          titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
          titleMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          bodyLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
          bodyMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          bodySmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)));

  static ThemeData darkTheme = ThemeData(
    fontFamily: 'Poppins',
    colorScheme: ColorScheme(
      brightness: Brightness.dark,
      primary: Color.fromRGBO(24, 192, 193, 1).withOpacity(0.8),
      onPrimary: Colors.white.withOpacity(0.8),
      secondary: Color.fromRGBO(217, 98, 47, 1).withOpacity(0.88),
      onSecondary: Color.fromRGBO(255, 255, 255, 0.7),
      error: Colors.redAccent,
      onError: Colors.black,
      surface: Color.fromRGBO(28, 32, 38, 1),
      onSurface: Color.fromRGBO(220, 230, 241, 1).withOpacity(0.8),
      secondaryContainer: Color.fromRGBO(24, 192, 193, 0.25),
    ),
    scaffoldBackgroundColor: Color.fromRGBO(18, 21, 25, 1),
    textTheme: TextTheme(
      titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
      titleMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
      bodyLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
      bodyMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      bodySmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
    ),
  );
}
