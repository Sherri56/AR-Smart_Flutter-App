import 'package:flutter/material.dart';
import 'dart:async';
import 'home_page.dart';
import 'theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'Flutter Demo',
            theme: ThemeData(
              brightness: Brightness.light,
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
              useMaterial3: true,
            ),
            darkTheme: ThemeData(
              brightness: Brightness.dark,
              scaffoldBackgroundColor: Colors.black,
              colorScheme: ColorScheme.dark(
                primary: Colors.white,
                secondary: Colors.grey,
                background: const Color(0xFF2D3436),
              ),
              textTheme: const TextTheme(
                bodyMedium: TextStyle(color: Colors.white),
              ),
              useMaterial3: true,
            ),
            themeMode:
                themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  // Dark gradient fades out.
  late Animation<double> _darkFadeAnimation;
  // Loading bar progress.
  late Animation<double> _progressAnimation;
  // Logo fades in.
  late Animation<double> _logoOpacityAnimation;
  // Ripple effect behind the logo.
  late Animation<double> _rippleAnimation;

  @override
  void initState() {
    super.initState();
    // Total duration is 8 seconds.
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    );

    // Dark gradient fades from fully opaque to transparent (0.0 to 0.4).
    _darkFadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.4, curve: Curves.easeInOut),
      ),
    );

    // Loading bar progresses from 0 to 1 (from 0.4 to 0.55).
    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 0.55, curve: Curves.easeInOut),
      ),
    );

    // Logo fades in from 0 to full opacity (from 0.55 to 1.0) slowly.
    _logoOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.55, 1.0, curve: Curves.easeInOut),
      ),
    );

    // Ripple effect expands concurrently with the logo fade in.
    _rippleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.55, 1.0, curve: Curves.easeOut),
      ),
    );

    _controller.forward();

    // After the animation completes, navigate to MyHomePage.
    Timer(const Duration(seconds: 8), () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const MyHomePage()),
      );
    });
  }

  void main() async {
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp();
    runApp(MyApp());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Underlying light gradient background.
    final lightGradient = const BoxDecoration(
      gradient: LinearGradient(
        colors: [
          Color(0xFFfeada6),
          Color(0xFFf5efef),
        ],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ),
    );

    // Dark gradient overlay.
    final darkGradient = const BoxDecoration(
      gradient: LinearGradient(
        colors: [
          Colors.black,
          Color(0xFF2D3436),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
    );

    return Scaffold(
      body: Container(
        decoration: lightGradient,
        child: Stack(
          children: [
            // Dark overlay that fades out.
            FadeTransition(
              opacity: _darkFadeAnimation,
              child: Container(
                decoration: darkGradient,
              ),
            ),
            // Loading bar positioned at bottom center.
            Positioned(
              bottom: 50,
              left: MediaQuery.of(context).size.width / 2 -
                  50, // Centered with width 100
              child: Container(
                width: 100,
                child: AnimatedBuilder(
                  animation: _progressAnimation,
                  builder: (context, child) {
                    return LinearProgressIndicator(
                      value: _progressAnimation.value,
                      backgroundColor: Colors.grey[300],
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(Colors.white),
                    );
                  },
                ),
              ),
            ),
            // Centered logo with ripple effect.
            Center(
              child: FadeTransition(
                opacity: _logoOpacityAnimation,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    AnimatedBuilder(
                      animation: _rippleAnimation,
                      builder: (context, child) {
                        double size = 150 + 100 * _rippleAnimation.value;
                        return Container(
                          width: size,
                          height: size,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white
                                  .withOpacity(1 - _rippleAnimation.value),
                              width: 4,
                            ),
                          ),
                        );
                      },
                    ),
                    Image.asset(
                      'assets/images/logo.png',
                      width: 150,
                      height: 150,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
