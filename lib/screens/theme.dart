// lib/theme.dart
import 'package:flutter/material.dart';

ThemeData appTheme() {
  return ThemeData(
    primaryColor: const Color(0xFF4CAF50), // Green for buttons
    scaffoldBackgroundColor: Colors.white, // White background
    textTheme: const TextTheme(
      headlineMedium: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: Colors.black,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        color: Color(0xFF8D6E63), // Light brown for secondary text
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF4CAF50), // Green button
        foregroundColor: Colors.white, // White text/icon on button
        minimumSize: const Size(double.infinity, 50), // Full width, 50 height
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10), // Rounded corners
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: const Color(0xFF8D6E63), // Light brown for text buttons
      ),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: Color(0xFFF5F5DC), // Beige background for text fields
      border: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(10)),
        borderSide: BorderSide.none, // No border
      ),
      labelStyle: TextStyle(
        color: Colors.black54, // Label color
      ),
    ),
  );
}