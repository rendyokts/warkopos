import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:warkopos/auth/login_screen.dart';
import 'package:warkopos/home/home_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Widget _initialScreen = const Scaffold(
    body: Center(child: CircularProgressIndicator()),
  );
  @override
  void initState() {
    super.initState();
    _loginCheck();
  }

  Future<void> _loginCheck() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      final isLoggedIn = token != null && token.isNotEmpty;

      if (mounted) {
        setState(() {
          _initialScreen =
              isLoggedIn ? const HomeScreen() : const LoginScreen();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _initialScreen = const LoginScreen();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Warkop POS',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: _initialScreen,
    );
  }
}
