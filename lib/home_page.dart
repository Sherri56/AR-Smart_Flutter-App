import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'terms_page.dart';
import 'styling_page.dart';
import 'dart:math';
import 'theme_provider.dart'; // Import theme provider

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with SingleTickerProviderStateMixin {
  bool _isChecked = false;
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _navigateToPage(Widget page) {
    _controller.forward(from: 0.0);
    Navigator.of(context).push(PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 600),
      pageBuilder: (context, animation, secondaryAnimation) {
        return FadeTransition(opacity: animation, child: page);
      },
    ));
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context); // Access theme provider

    return Scaffold(
      body: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: themeProvider.isDarkMode
                ? [Colors.black, const Color(0xFF2D3436)] // Dark mode colors
                : [const Color(0xFFfeada6), const Color(0xFFf5efef)], // Light mode colors
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/logo.png',
              height: 100,
            ),
            const SizedBox(height: 24),
            Text(
              'WELCOME',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: themeProvider.isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'REFLECT YOUR BEAUTY\nPERFECT YOUR STYLE',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                color: themeProvider.isDarkMode ? Colors.white70 : Colors.black87,
              ),
            ),
            const SizedBox(height: 32),
            GestureDetector(
              onTap: () {
                if (_isChecked) {
                  _showSparkles();
                  Future.delayed(const Duration(milliseconds: 800), () {
                    _navigateToPage(const StylingPage());
                  });
                } else {
                  _showTermsDialog();
                }
              },
              child: Stack(
                alignment: Alignment.center,
                children: [
                  AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      return CustomPaint(
                        painter: SparklePainter(_controller.value),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 36),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFF7EB3), Color(0xFFFF758C)],
                            ),
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.pink.withOpacity(0.4),
                                blurRadius: 15,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: const Text(
                            'START STYLING',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Checkbox(
                  value: _isChecked,
                  onChanged: (value) {
                    setState(() {
                      _isChecked = value!;
                    });
                  },
                  activeColor: Colors.pinkAccent,
                ),
                const Text('Agree to '),
                GestureDetector(
                  onTap: () {
                    _navigateToPage(const TermsPage());
                  },
                  child: const Text(
                    'Terms of Service',
                    style: TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            // Theme Toggle Button at Bottom Center
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 30.0), // Adjust spacing from bottom
                child: IconButton(
                  icon: Icon(
                    themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                    size: 30,
                    color: themeProvider.isDarkMode ? Colors.white : Colors.black,
                  ),
                  onPressed: () {
                    themeProvider.toggleTheme();
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSparkles() {
    _controller.forward(from: 0.0);
  }

  void _showTermsDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Agree to Terms"),
          content: const Text("You must agree to the Terms of Service to proceed."),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }
}

class SparklePainter extends CustomPainter {
  final double progress;
  SparklePainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = Colors.white.withOpacity(1 - progress)
      ..strokeWidth = 2
      ..style = PaintingStyle.fill;

    final Random random = Random();
    for (int i = 0; i < 20; i++) {
      double x = random.nextDouble() * size.width;
      double y = random.nextDouble() * size.height;
      double radius = (random.nextDouble() * 4) + 2;
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
