import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:smart/eyebrow.dart';
import 'lipstick.dart';
import 'nail_paint_page.dart';
import 'foundation_page.dart';
import 'package:provider/provider.dart';
import 'theme_provider.dart'; // Import ThemeProvider

class StylingPage extends StatelessWidget {
  const StylingPage({super.key});

  @override
  Widget build(BuildContext context) {
    //final themeProvider = Provider.of<ThemeProvider>(context);
    //bool isDarkMode = themeProvider.isDarkMode;
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Scaffold(
          body: Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: themeProvider.isDarkMode
                    ? [
                        Colors.black,
                        const Color(0xFF2D3436)
                      ] // Dark mode colors
                    : [
                        const Color(0xFFfeada6),
                        const Color(0xFFf5efef)
                      ], // Light mode colors
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Center(
              child: Container(
                margin: const EdgeInsets.only(top: 20.0),
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: themeProvider.isDarkMode
                        ? Colors.white70
                        : Colors.white,
                    width: 2,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Back Button
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            Navigator.pop(context);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8.0),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(Icons.arrow_back,
                                color: Colors.black),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          "PERFECT YOUR STYLE",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: themeProvider.isDarkMode
                                ? Colors.white
                                : const Color.fromARGB(255, 255, 255, 255),
                          ),
                        ),
                        const Spacer(),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Buttons with Sparkle Effect
                    SparkleButton(
                      text: "Lipstick",
                      imagePath: "assets/images/lipstickpage.svg",
                      color: const Color(0xFFFFC2D1),
                      onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const LipstickPage()));
                      },
                    ),

                    SparkleButton(
                      text: "Nail Paint",
                      imagePath: "assets/images/nailpaint.svg",
                      color: const Color(0xFFFFB3C6),
                      isNailPaint: true,
                      onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const NailPaintPage()));
                      },
                    ),

                    SparkleButton(
                      text: "Foundation",
                      imagePath: "assets/images/foundationPage.png",
                      color: const Color(0xFFFF8FAB),
                      isNailPaint: true,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const FoundationPage(),
                          ),
                        );
                      },
                    ),

                    SparkleButton(
                      text: "Eye Brow",
                      imagePath: "assets/images/eyebrowpage.png",
                      color: const Color(0xFFFB6F92),
                      onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const EyeBrowPage()));
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// Sparkle Button Widget with Animation
class SparkleButton extends StatefulWidget {
  final String text;
  final String imagePath;
  final Color color;
  final VoidCallback onTap;
  final bool isNailPaint;
  final bool removeTextPadding;

  const SparkleButton({
    super.key,
    required this.text,
    required this.imagePath,
    required this.color,
    required this.onTap,
    this.isNailPaint = false,
    this.removeTextPadding = false,
  });

  @override
  _SparkleButtonState createState() => _SparkleButtonState();
}

class _SparkleButtonState extends State<SparkleButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  void _startAnimation() {
    _controller.forward(from: 0);
    Future.delayed(const Duration(milliseconds: 400), () {
      widget.onTap();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Define isDarkMode in this scope.
    final themeProvider = Provider.of<ThemeProvider>(context);
    bool isDarkMode = themeProvider.isDarkMode;

    return GestureDetector(
      onTap: _startAnimation,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Sparkle Effect (Moved BELOW the button)
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  return CustomPaint(
                    painter: SparklePainter(_animation.value),
                  );
                },
              ),
            ),
          ),

          // The Button (Now ABOVE the sparkles)
          Container(
            height: widget.isNailPaint ? 110 : 120,
            margin: const EdgeInsets.symmetric(vertical: 10.0),
            decoration: BoxDecoration(
              borderRadius: widget.isNailPaint
                  ? const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      bottomLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    )
                  : BorderRadius.circular(20),
              color: widget.color,
              boxShadow: [
                BoxShadow(
                  color: Colors.pink.withOpacity(0.4),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: widget.imagePath.contains("eyebrow")
                      ? const BorderRadius.only(
                          topLeft: Radius.circular(20),
                          bottomLeft: Radius.circular(20),
                          topRight: Radius.circular(
                              20), // ✅ round top-right for eyebrow
                        )
                      : widget.isNailPaint
                          ? const BorderRadius.only(
                              topLeft: Radius.circular(20),
                              bottomLeft: Radius.circular(20),
                              topRight: Radius.circular(20),
                            )
                          : const BorderRadius.only(
                              topLeft: Radius.circular(20),
                              bottomLeft: Radius.circular(20),
                            ),
                  child: Container(
                    height: widget.isNailPaint
                        ? 110
                        : 120, // same as the button height
                    width: 130, // slightly wider for better fill
                    child: SizedBox.expand(
                      child: widget.imagePath.toLowerCase().endsWith('.svg')
                          ? SvgPicture.asset(
                              widget.imagePath,
                              fit: BoxFit.fill,
                            )
                          : Image.asset(
                              widget.imagePath,
                              fit: BoxFit.fill,
                            ),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Padding(
                  padding: widget.removeTextPadding
                      ? EdgeInsets.zero
                      : const EdgeInsets.only(left: 20.0),
                  child: Text(
                    widget.text,
                    // CHANGED: Set the toggle option for all buttons
                    style: TextStyle(
                      color: isDarkMode
                          ? const Color.fromARGB(255, 0, 0, 0)
                          : const Color.fromARGB(255, 255, 255, 255),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

// SparklePainter Class for Custom Animation
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
  bool shouldRepaint(SparklePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
