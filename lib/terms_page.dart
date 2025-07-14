import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Import provider
import 'home_page.dart';
import 'styling_page.dart';
import 'theme_provider.dart'; // Import theme provider

class TermsPage extends StatelessWidget {
  const TermsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Scaffold(
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: themeProvider.isDarkMode
                    ? [Colors.black, const Color(0xFF2D3436)] // Dark mode colors
                    : [const Color(0xFFfeada6), const Color(0xFFf5efef)], // Light mode colors
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            Navigator.pop(context);
                          },
                          child: Icon(
                            Icons.arrow_back,
                            color: themeProvider.isDarkMode ? Colors.white : Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Terms of Service",
                              style: TextStyle(
                                fontSize: 24.0,
                                fontWeight: FontWeight.bold,
                                color: themeProvider.isDarkMode ? Colors.white : Colors.black,
                              ),
                            ),
                            const SizedBox(height: 8.0),
                            Text(
                              "Last Updated on December 2024",
                              style: TextStyle(
                                fontSize: 14.0,
                                color: themeProvider.isDarkMode ? Colors.white70 : Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 16.0),
                            Text(
                              "Summary",
                              style: TextStyle(
                                fontSize: 20.0,
                                fontWeight: FontWeight.bold,
                                color: themeProvider.isDarkMode ? Colors.white : Colors.black,
                              ),
                            ),
                            const SizedBox(height: 8.0),
                            Text(
                              "Welcome to the Augmented Reality (AR) Smart Mirror application. This cutting-edge platform provides a hygienic and efficient way to try on cosmetics virtually, offering an innovative and personalized shopping experience. By using this application, you agree to adhere to our terms and conditions outlined below. Please review them carefully to ensure a clear understanding of your rights and obligations.",
                              textAlign: TextAlign.justify,
                              style: TextStyle(
                                fontSize: 14.0,
                                color: themeProvider.isDarkMode ? Colors.white70 : Colors.black,
                              ),
                            ),
                            const SizedBox(height: 16.0),
                            // Terms Details
                            Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: 'Terms\n',
                                    style: TextStyle(
                                      fontSize: 20.0,
                                      fontWeight: FontWeight.bold,
                                      color: themeProvider.isDarkMode ? Colors.white : Colors.black,
                                    ),
                                  ),
                                  const TextSpan(text: '\n'),
                                  TextSpan(
                                    text: 'Usage of the Application\n',
                                    style: TextStyle(
                                      fontSize: 16.0,
                                      fontWeight: FontWeight.bold,
                                      color: themeProvider.isDarkMode ? Colors.white : Colors.black,
                                    ),
                                  ),
                                  const TextSpan(text: '\n'),
                                  TextSpan(
                                    text:
                                        '• The AR Smart Mirror is designed to provide virtual makeup, hairstyle, and nail color visualization services.\n• You agree to use the application responsibly and refrain from attempting to alter or misuse the platform.\n\n',
                                    style: TextStyle(
                                      fontSize: 14.0,
                                      color: themeProvider.isDarkMode ? Colors.white70 : Colors.black,
                                    ),
                                  ),
                                  TextSpan(
                                    text: 'Data Privacy\n',
                                    style: TextStyle(
                                      fontSize: 16.0,
                                      fontWeight: FontWeight.bold,
                                      color: themeProvider.isDarkMode ? Colors.white : Colors.black,
                                    ),
                                  ),
                                  const TextSpan(text: '\n'),
                                  TextSpan(
                                    text:
                                        '• The application collects minimal data to enhance your experience.\n• All data will be used in accordance with privacy laws and not shared with third parties without explicit consent.\n\n',
                                    style: TextStyle(
                                      fontSize: 14.0,
                                      color: themeProvider.isDarkMode ? Colors.white70 : Colors.black,
                                    ),
                                  ),
                                  TextSpan(
                                    text: 'Intellectual Property\n',
                                    style: TextStyle(
                                      fontSize: 16.0,
                                      fontWeight: FontWeight.bold,
                                      color: themeProvider.isDarkMode ? Colors.white : Colors.black,
                                    ),
                                  ),
                                  const TextSpan(text: '\n'),
                                  TextSpan(
                                    text:
                                        '• All content, including the AR technology and user interface, is the intellectual property of the development team and the University of Gujrat. Unauthorized use or duplication is strictly prohibited.\n\n',
                                    style: TextStyle(
                                      fontSize: 14.0,
                                      color: themeProvider.isDarkMode ? Colors.white70 : Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                              textAlign: TextAlign.justify,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const MyHomePage(),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(30),
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
                                'Decline',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16.0),
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const StylingPage(),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(30),
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
                                'Accept',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
