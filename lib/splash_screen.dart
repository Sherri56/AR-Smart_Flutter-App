import 'package:flutter/material.dart';
import 'dart:async';
import 'home_page.dart'; // Import HomePage

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const SplashScreen(), // Show the SplashScreen first
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Timer to navigate to HomePage after the splash screen
    Timer(const Duration(seconds: 3), () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const MyHomePage()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFfeada6),
              Color(0xFFf5efef),
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
        ),
        child: Center(
          child: InkWell(
            onTap: () {}, // This can be empty, just to show the ripple effect
            splashColor: Colors.blue.withOpacity(0.6), // Color of the ripple
            highlightColor: Colors.green.withOpacity(0.6), // Highlight color
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.transparent,
              ),
              child: Center(
                child: Image.asset(
                  'assets/images/logo.png', // Your logo asset
                  width: 150,
                  height: 150,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}