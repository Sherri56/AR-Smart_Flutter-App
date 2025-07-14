import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_database/firebase_database.dart';
import 'theme_provider.dart';
import 'package:flutter/services.dart';

class FoundationPage extends StatefulWidget {
  const FoundationPage({super.key});

  @override
  _FoundationPageState createState() => _FoundationPageState();
}

class _FoundationPageState extends State<FoundationPage> {
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  bool _isCameraInitialized = false;
  bool _hasPermission = false;
  bool _isProcessing = false;
  CameraLensDirection _currentCameraDirection =
      CameraLensDirection.front; // Track current camera

  Timer? _detectionTimer;
  bool _isDetecting = false;
  final DatabaseReference _databaseRef = FirebaseDatabase.instance.ref();

  String? _selectedShadeHex;
  double _opacity = 0.7;
  Uint8List? _processedImageBytes;
  StreamSubscription? _firebaseSubscription;

  // Foundation shades - neutral skin tones
  final List<Color> _foundationShades = [
    const Color(0xFFF5D0B9), // Porcelain
    const Color(0xFFEEC1A2), // Ivory
    const Color(0xFFE0AC8B), // Beige
    const Color(0xFFD19C7C), // Sand
    const Color(0xFFB07D62), // Honey
    const Color(0xFF8C5D45), // Caramel
    const Color(0xFF5D4037), // Espresso
    const Color(0xFF3E2723), // Mocha
  ];

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    _checkCameraPermission();
    _initFirebaseListener();
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    _detectionTimer?.cancel();
    _cameraController?.dispose();
    _firebaseSubscription?.cancel();
    super.dispose();
  }

  void _initFirebaseListener() {
    _firebaseSubscription =
        _databaseRef.child('foundation_shade').onValue.listen((event) {
      final data = event.snapshot.value as Map?;
      if (data != null) {
        if (data['shade'] != null && _selectedShadeHex != data['shade']) {
          setState(() {
            _selectedShadeHex = data['shade'].toString();
          });
          _startDetectionLoop();
        }
        if (data['opacity'] != null && _opacity != data['opacity']) {
          setState(() {
            _opacity = double.parse(data['opacity'].toString());
          });
        }
      }
    });
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
        // Find the requested camera direction or default to the first camera
        final camera = _cameras.firstWhere(
          (camera) => camera.lensDirection == _currentCameraDirection,
          orElse: () => _cameras[0],
        );

        // Store the current camera direction
        _currentCameraDirection = camera.lensDirection;

        _cameraController = CameraController(
          camera,
          ResolutionPreset.high,
          imageFormatGroup: ImageFormatGroup.jpeg,
        );

        await _cameraController!.initialize().then((_) {
          if (mounted) {
            setState(() {
              _isCameraInitialized = true;
            });
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Camera error: ${e.toString()}")),
        );
      }
    }
  }

  // Switch between front and back cameras
  Future<void> _switchCamera() async {
    if (_cameras.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No additional cameras available")),
      );
      return;
    }

    setState(() {
      _isCameraInitialized = false;
      _processedImageBytes = null; // Clear current processed image
    });

    // Toggle camera direction
    _currentCameraDirection =
        _currentCameraDirection == CameraLensDirection.front
            ? CameraLensDirection.back
            : CameraLensDirection.front;

    // Dispose current controller before initializing new one
    await _cameraController?.dispose();
    _cameraController = null;

    // Initialize with new camera
    await _initializeCamera();

    // If a shade was selected, restart detection
    if (_selectedShadeHex != null) {
      _startDetectionLoop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    bool isDarkMode = themeProvider.isDarkMode;
    final bgColor = isDarkMode ? Colors.black : const Color(0xFFFFC2D1);
    final textColor = isDarkMode ? Colors.white : Colors.white;

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          _processedImageBytes != null
              ? _buildProcessedImage()
              : _buildCameraPreview(isDarkMode),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: Icon(Icons.arrow_back, color: textColor),
                onPressed: () => Navigator.pop(context),
              ),
              title: Text(
                "Foundation - Start Styling",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              actions: [
                // Camera switch button
                IconButton(
                  icon: Icon(Icons.flip_camera_ios, color: textColor),
                  onPressed: _isCameraInitialized ? _switchCamera : null,
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildBottomControls(isDarkMode, textColor),
          ),
          if (_isProcessing) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }

  Widget _buildProcessedImage() {
    // For processed image, we only need to mirror if using front camera
    final shouldMirror = _currentCameraDirection == CameraLensDirection.front;

    return SizedBox(
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.height,
      child: Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()..scale(shouldMirror ? -1.0 : 1.0, 1.0),
        child: Image.memory(
          _processedImageBytes!,
          fit: BoxFit.cover,
          gaplessPlayback: true,
        ),
      ),
    );
  }

  Widget _buildCameraPreview(bool isDarkMode) {
    if (!_hasPermission) {
      return Container(
        color: Colors.black,
        child: Center(
          child: ElevatedButton(
            onPressed: _checkCameraPermission,
            child: const Text("Enable Camera"),
          ),
        ),
      );
    }

    if (!_isCameraInitialized) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // For camera preview, we only need to mirror if using front camera
    final shouldMirror = _currentCameraDirection == CameraLensDirection.front;

    return SizedBox(
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.height,
      child: RotatedBox(
        quarterTurns: 1,
        child: Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()..scale(shouldMirror ? -1.0 : 1.0, 1.0),
          child: CameraPreview(_cameraController!),
        ),
      ),
    );
  }

  Widget _buildBottomControls(bool isDarkMode, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      decoration: BoxDecoration(
        color: isDarkMode
            ? Colors.black.withOpacity(0.5)
            : const Color(0xFFFFC2D1).withOpacity(0.7),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          _buildShadeOptions(isDarkMode),
          const SizedBox(height: 8),
          _buildOpacitySlider(isDarkMode),
          const SizedBox(height: 8),
          _buildActionButtons(isDarkMode, textColor),
        ],
      ),
    );
  }

  Widget _buildShadeOptions(bool isDarkMode) {
    return SizedBox(
      height: 70,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _foundationShades.length,
        itemBuilder: (context, index) {
          final shadeHex =
              _foundationShades[index].value.toRadixString(16).substring(2);
          return GestureDetector(
            onTap: () => _selectShade(shadeHex),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: _foundationShades[index],
                shape: BoxShape.circle,
                border: _selectedShadeHex == shadeHex
                    ? Border.all(color: Colors.white, width: 3)
                    : null,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildOpacitySlider(bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Row(
        children: [
          Icon(Icons.opacity, color: isDarkMode ? Colors.white : Colors.black),
          Expanded(
            child: Slider(
              value: _opacity,
              min: 0.1,
              max: 1.0,
              onChanged: (value) {
                setState(() => _opacity = value);
                _databaseRef
                    .child('foundation_shade')
                    .update({'opacity': value});
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(bool isDarkMode, Color textColor) {
    return Scrollbar(
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
              onTap: _clearSelections,
              isDarkMode: isDarkMode,
              textColor: textColor,
            ),
            _buildIconWithLabel(
              iconPath: 'assets/images/end_Session.png',
              label: 'END SESSION',
              onTap: _showEndSessionDialog,
              isSvg: false,
              isDarkMode: isDarkMode,
              textColor: textColor,
            ),
            const SizedBox(width: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildIconWithLabel({
    required String iconPath,
    required String label,
    required VoidCallback onTap,
    bool isSvg = true,
    double iconSize = 40.0,
    bool isDarkMode = false,
    required Color textColor,
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
                    color: textColor,
                  )
                : Image.asset(
                    iconPath,
                    height: iconSize,
                    width: iconSize,
                    color: textColor,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(Icons.broken_image,
                          size: iconSize, color: textColor);
                    },
                  ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectShade(String shadeHex) async {
    setState(() => _isProcessing = true);

    try {
      await _databaseRef.child('foundation_shade').update({
        'shade': shadeHex,
        'opacity': _opacity,
        'detection_status': 'processing'
      });
      await _captureAndSendImage();
      _startDetectionLoop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Shade update failed: ${e.toString()}")),
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _clearSelections() {
    _detectionTimer?.cancel();
    setState(() {
      _selectedShadeHex = null;
      _processedImageBytes = null;
    });
    _databaseRef.child('foundation_shade').update({'shade': null});

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Foundation cleared!",
            style: TextStyle(fontWeight: FontWeight.bold)),
      ));
    }
  }

  Future<void> _captureAndSendImage() async {
    if (_isProcessing || !_cameraController!.value.isInitialized) return;

    try {
      setState(() => _isProcessing = true);
      final XFile file = await _cameraController!.takePicture();
      final imageBytes = await file.readAsBytes();

      final request = http.MultipartRequest(
          'POST', Uri.parse('http://192.168.160.206:5000/detect_foundation'));

      // Add information about camera direction to help server process correctly
      request.fields['camera_direction'] = _currentCameraDirection.toString();

      request.files.add(http.MultipartFile.fromBytes(
        'image',
        imageBytes,
        filename: 'foundation.jpg',
      ));

      final response = await request.send();
      final responseBytes = await response.stream.toBytes();

      if (response.statusCode == 200) {
        setState(() {
          _processedImageBytes = responseBytes;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Detection failed: ${response.statusCode}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}")),
      );
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  void _startDetectionLoop() {
    _detectionTimer?.cancel();

    _detectionTimer =
        Timer.periodic(Duration(milliseconds: 500), (timer) async {
      if (_selectedShadeHex != null && !_isDetecting) {
        _isDetecting = true;
        try {
          await _captureAndSendImage();

          final snapshot = await _databaseRef.child('foundation_shade').get();
          if (snapshot.exists) {
            final status = snapshot.child('detection_status').value.toString();
            if (status.contains('error')) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Detection error: $status")),
              );
            }
          }
        } finally {
          _isDetecting = false;
        }
      }
    });
  }

  void _showEndSessionDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Provider.of<ThemeProvider>(context).isDarkMode
              ? Colors.black
              : const Color(0xFFFFC2D1),
          title: Text(
            "End Session?",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Provider.of<ThemeProvider>(context).isDarkMode
                  ? Colors.white
                  : Colors.black,
            ),
          ),
          content: Text(
            "Are you sure you want to end this styling session?",
            style: TextStyle(
              color: Provider.of<ThemeProvider>(context).isDarkMode
                  ? Colors.white
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
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text(
                "Yes, End Session",
                style:
                    TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }
}
