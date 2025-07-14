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

class LipstickPage extends StatefulWidget {
  const LipstickPage({super.key});

  @override
  _LipstickPageState createState() => _LipstickPageState();
}

class _LipstickPageState extends State<LipstickPage> {
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

  String? _selectedColorHex;
  double _opacity = 0.7;
  Uint8List? _processedImageBytes;
  StreamSubscription? _firebaseSubscription;

  final List<Color> _lipstickColors = [
    const Color(0xFFD10000),
    const Color(0xFFFF69B4),
    const Color(0xFFE3C9B5),
    const Color(0xFF991C42),
    const Color(0xFFFF7F50),
    const Color(0xFF915F6D),
    const Color(0xFF800020),
    const Color(0xFFFFDAB9),
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
        _databaseRef.child('lip_color').onValue.listen((event) {
      final data = event.snapshot.value as Map?;
      if (data != null) {
        if (data['color'] != null && _selectedColorHex != data['color']) {
          setState(() {
            _selectedColorHex = data['color'].toString();
          });
          // Start detection when color changes
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

    // If a color was selected, restart detection
    if (_selectedColorHex != null) {
      _startDetectionLoop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    bool isDarkMode = themeProvider.isDarkMode;
    final bgColor = isDarkMode ? Colors.black : const Color(0xFFFFC2D1);
    final textColor = isDarkMode
        ? const Color.fromARGB(255, 255, 255, 255)
        : const Color.fromARGB(255, 255, 255, 255);

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          // Show processed image if available, otherwise show camera preview
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
                "Lipstick - Start Styling",
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
    final shouldMirror = _currentCameraDirection == CameraLensDirection.front;
    final aspectRatio = _cameraController?.value.aspectRatio ?? 1.0;

    return Center(
      child: SizedBox(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.width * aspectRatio,
        child: Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()..scale(shouldMirror ? -1.0 : 1.0, 1.0),
          child: Image.memory(
            _processedImageBytes!,
            fit: BoxFit.cover,
            gaplessPlayback: true,
          ),
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
          _buildColorOptions(isDarkMode),
          const SizedBox(height: 8),
          _buildOpacitySlider(isDarkMode),
          const SizedBox(height: 8),
          _buildActionButtons(isDarkMode, textColor),
        ],
      ),
    );
  }

  Widget _buildColorOptions(bool isDarkMode) {
    return SizedBox(
      height: 70,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _lipstickColors.length,
        itemBuilder: (context, index) {
          final colorHex =
              _lipstickColors[index].value.toRadixString(16).substring(2);
          return GestureDetector(
            onTap: () => _selectColor(colorHex),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: _lipstickColors[index],
                shape: BoxShape.circle,
                border: _selectedColorHex == colorHex
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
                _databaseRef.child('lip_color').update({'opacity': value});
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
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Future<void> _selectColor(String colorHex) async {
    setState(() => _isProcessing = true);

    try {
      // Update Firebase with new color
      await _databaseRef.child('lip_color').update({
        'color': colorHex,
        'opacity': _opacity,
        'detection_status': 'processing'
      });

      // Immediately capture and process image
      await _captureAndSendImage();

      // Start continuous detection
      _startDetectionLoop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Color update failed: ${e.toString()}")),
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _clearSelections() {
    _detectionTimer?.cancel(); // Stop the detection loop

    setState(() {
      _selectedColorHex = null;
      _processedImageBytes = null;
    });

    _databaseRef.child('lip_color').update({'color': null});

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Selections cleared!",
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
          'POST', Uri.parse('http://192.168.160.206:5000/detect'));

      // Add information about camera direction to help server process correctly
      request.fields['camera_direction'] = _currentCameraDirection.toString();

      request.files.add(http.MultipartFile.fromBytes(
        'image',
        imageBytes,
        filename: 'lipstick.jpg',
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
    _detectionTimer?.cancel(); // Cancel previous timer

    _detectionTimer =
        Timer.periodic(Duration(milliseconds: 300), (timer) async {
      if (_selectedColorHex != null && !_isDetecting) {
        _isDetecting = true;
        try {
          await _captureAndSendImage();

          // Check Firebase for any errors
          final snapshot = await _databaseRef.child('lip_color').get();
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
