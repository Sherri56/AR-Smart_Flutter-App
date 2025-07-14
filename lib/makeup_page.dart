import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:permission_handler/permission_handler.dart';
import 'lipstick.dart'; // Import LipstickPage
import 'foundation_page.dart';
import 'package:provider/provider.dart';
import 'theme_provider.dart'; // Import ThemeProvider

class MakeupPage extends StatefulWidget {
  const MakeupPage({super.key});

  @override
  _MakeupPageState createState() => _MakeupPageState();
}

class _MakeupPageState extends State<MakeupPage> {
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  bool _isCameraInitialized = false;
  bool _hasPermission = false;

  @override
  void initState() {
    super.initState();
    _checkCameraPermission();
  }

  Future<void> _checkCameraPermission() async {
    var status = await Permission.camera.status;
    if (status.isGranted) {
      _hasPermission = true;
      await _initializeCamera();
    } else {
      var result = await Permission.camera.request();
      if (result.isGranted) {
        _hasPermission = true;
        await _initializeCamera();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Camera permission denied. Enable it in settings.",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        );
      }
    }
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isNotEmpty) {
        _cameraController = CameraController(
          _cameras.firstWhere(
            (camera) => camera.lensDirection == CameraLensDirection.front,
            orElse: () => _cameras[0],
          ),
          ResolutionPreset.high,
        );
        await _cameraController!.initialize();
        setState(() {
          _isCameraInitialized = true;
        });
      } else {
        throw Exception("No cameras available.");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error initializing camera: $e")),
      );
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
     final themeProvider = Provider.of<ThemeProvider>(context);
    bool isDarkMode = themeProvider.isDarkMode;
    return Scaffold(
      backgroundColor: isDarkMode ? Colors.black :  Color(0xFFFFC2D1),
      body: Container(
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.black : const Color(0xFFFFC2D1),
        ),
        child: Column(
          children: [
            // App Bar
            AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
               leading: IconButton(
                icon: Icon(Icons.home,
                    color: isDarkMode ?  Color.fromARGB(255, 255, 255, 255) : const Color.fromARGB(255, 255, 255, 255)),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
              title: Text(
                "Virtual Makeup - Start Styling",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDarkMode ? Color.fromARGB(255, 255, 255, 255) : const Color.fromARGB(255, 255, 255, 255),),
              ),
            ),

            // Camera Preview
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.black : const Color(0xFFFFC2D1),
                ),
                child: Center(
                  child: _hasPermission
                      ? (_isCameraInitialized
                          ? SizedBox(
                              width: MediaQuery.of(context).size.width,
                              height: MediaQuery.of(context).size.height,
                              child: RotatedBox(
                  quarterTurns: 1,
                  child: Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()..scale(-1.0, 1.0),
                    child: CameraPreview(_cameraController!),
                  ),
                ),
                            )
                          : const CircularProgressIndicator())
                      : ElevatedButton(
                          onPressed: _checkCameraPermission,
                          child: const Text("Enable Camera"),
                        ),
                ),
              ),
            ),

            // Bottom Menu (Horizontal Scrollable)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.black : Color(0xFFFFC2D1),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Scrollbar(
                thickness: 3.0,
                radius: const Radius.circular(10),
                thumbVisibility: true,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      const SizedBox(width: 10),

                     _buildIconWithLabel(
                        iconPath: 'assets/images/clear all.svg',
                        label: 'CLEAR ALL',
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Selections cleared!",
                                  style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          );
                        },
                        isDarkMode: isDarkMode,
                      ),
                      _buildIconWithLabel(
                        iconPath: 'assets/images/foundation.svg',
                        label: 'FOUNDATION',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const FoundationPage()),
                          );
                        },
                        isDarkMode: isDarkMode,
                      ),
                      _buildIconWithLabel(
                        iconPath: 'assets/images/lipstick.svg',
                        label: 'LIPSTICK',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const LipstickPage()),
                          );
                        },
                        isDarkMode: isDarkMode,
                      ),
                      _buildIconWithLabel(
                        iconPath: 'assets/images/end_session.png',
                        onTap: _showEndSessionDialog,
                        label: 'END SESSION',
                        isSvg: false,
                        isDarkMode: isDarkMode,
                      ),

                      const SizedBox(width: 10),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEndSessionDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor:
              Provider.of<ThemeProvider>(context).isDarkMode ? Colors.black :  Color(0xFFFFC2D1),
          title: Text(
            "End Session?",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Provider.of<ThemeProvider>(context).isDarkMode
                  ?  Color.fromARGB(255, 255, 255, 255)
                  : Colors.black,
            ),
          ),
           content: Text(
            "Are you sure you want to end this styling session?",
            style: TextStyle(
              color: Provider.of<ThemeProvider>(context).isDarkMode
                  ? Color.fromARGB(255, 255, 255, 255)
                  : Colors.black87,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Navigate back
              },
              child: const Text(
                "Yes, End Session",
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildIconWithLabel({
    required String iconPath,
    required String label,
    required VoidCallback onTap,
    bool isSvg = true,
    double iconSize = 40.0,
    bool isDarkMode = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: onTap,
            child: isSvg
                ? SvgPicture.asset(
                    iconPath,
                    height: iconSize,
                    width: iconSize,
                   color: isDarkMode ? Color.fromARGB(255, 255, 255, 255) : const Color.fromARGB(255, 255, 255, 255),
                  )
                : Image.asset(
                    iconPath,
                    height: iconSize,
                    width: iconSize,
                    color: Colors.white,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(Icons.broken_image,
                          size: iconSize,
                          color: isDarkMode ?  Color.fromARGB(255, 255, 255, 255) : const Color.fromARGB(255, 255, 255, 255));
                    },
                  ),
          ),
          const SizedBox(height: 4),
         Text(
            label,
            style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Color.fromARGB(255, 255, 255, 255) : const Color.fromARGB(255, 255, 255, 255)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
