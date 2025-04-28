import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/home_screen.dart';
import 'screens/item_detail_screen.dart';
import 'screens/favorites_screen.dart';
import 'screens/cart_screen.dart';
import 'screens/order_detail_screen.dart';
import 'screens/order_history_screen.dart';
import 'screens/account_screen.dart';

// Define the appTheme function
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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://vsowmjhuiqvfezqapdou.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZzb3dtamh1aXF2ZmV6cWFwZG91Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDI3MDAwNjAsImV4cCI6MjA1ODI3NjA2MH0.Ip5_zg8ASgCU5jRYt31YEVB2LBKMXB3MOBCzh6A4Xsk',
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Grocify',
      theme: appTheme(), // Apply the custom theme here
      initialRoute: '/login',
      routes: {
        '/login': (context) => LoginScreen(),
        '/signup': (context) => SignupScreen(),
        '/home': (context) => HomeScreen(),
        '/favorites': (context) => FavoritesScreen(),
        '/cart': (context) => CartScreen(),
        '/orderHistory': (context) => OrderHistoryScreen(),
        '/account': (context) => AccountScreen(),
        '/OrderDetail': (context) => OrderDetailScreen(orderId: 'defaultOrderId'),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/itemDetail') {
          final Map<String, dynamic> product =
              settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
              builder: (context) => ItemDetailScreen(product: product));
        } else if (settings.name == '/orderDetail') {
          final String orderId = settings.arguments as String; // Fixed type from int to String
          return MaterialPageRoute(
            builder: (context) => OrderDetailScreen(orderId: orderId),
          );
        }
        return null;
      },
    );
  }
}