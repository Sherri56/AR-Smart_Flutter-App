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

class NailPaintPage extends StatefulWidget {
  const NailPaintPage({super.key});

  @override
  _NailPaintPageState createState() => _NailPaintPageState();
}

class _NailPaintPageState extends State<NailPaintPage> {
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  bool _isCameraInitialized = false;
  bool _hasPermission = false;
  bool _isProcessing = false;
  CameraLensDirection _currentCameraDirection =
      CameraLensDirection.front; // Track current camera

  // Add these to your state class
  String _selectedShape = 'oval';
  double _nailLength = 1.0;

  Timer? _detectionTimer;
  bool _isDetecting = false;
  final DatabaseReference _databaseRef = FirebaseDatabase.instance.ref();

  String? _selectedColorHex;
  double _opacity = 0.7;
  Uint8List? _processedImageBytes;
  StreamSubscription? _firebaseSubscription;

  // List of nail polish colors
  final List<Color> _nailColors = [
    Colors.red,
    Colors.pink,
    Colors.purple,
    Colors.deepPurple,
    Colors.indigo,
    Colors.blue,
    Colors.lightBlue,
    Colors.cyan,
    Colors.teal,
    Colors.green,
    Colors.lightGreen,
    Colors.lime,
    Colors.yellow,
    Colors.amber,
    Colors.orange,
    Colors.deepOrange,
    Colors.brown,
    Colors.grey,
    Colors.blueGrey,
    Colors.black,
    Colors.white,
    const Color(0xFFC2185B), // Dark Pink
    const Color(0xFFE91E63), // Pink
    const Color(0xFF9C27B0), // Purple
    const Color(0xFF673AB7), // Deep Purple
    const Color(0xFF3F51B5), // Indigo
    const Color(0xFF2196F3), // Blue
    const Color(0xFF03A9F4), // Light Blue
    const Color(0xFF00BCD4), // Cyan
    const Color(0xFF009688), // Teal
    const Color(0xFF4CAF50), // Green
    const Color(0xFF8BC34A), // Light Green
    const Color(0xFFCDDC39), // Lime
    const Color(0xFFFFEB3B), // Yellow
    const Color(0xFFFFC107), // Amber
    const Color(0xFFFF9800), // Orange
    const Color(0xFFFF5722), // Deep Orange
    const Color(0xFF795548), // Brown
    const Color(0xFF607D8B), // Blue Grey
    const Color(0xFFFFF9C4), // Pale Yellow
    const Color(0xFFFFCDD2), // Pale Pink
    const Color(0xFFF8BBD0), // Light Pink
    const Color(0xFFE1BEE7), // Light Purple
    const Color(0xFFD1C4E9), // Light Deep Purple
    const Color(0xFFC5CAE9), // Light Indigo
    const Color(0xFFBBDEFB), // Light Blue
    const Color(0xFFB3E5FC), // Light Light Blue
    const Color(0xFFB2EBF2), // Light Cyan
    const Color(0xFFB2DFDB), // Light Teal
    const Color(0xFFC8E6C9), // Light Green
    const Color(0xFFDCEDC8), // Light Light Green
    const Color(0xFFF0F4C3), // Light Lime
    const Color(0xFFFFF9C4), // Light Yellow
    const Color(0xFFFFECB3), // Light Amber
    const Color(0xFFFFE0B2), // Light Orange
    const Color(0xFFFFCCBC), // Light Deep Orange
    const Color(0xFFD7CCC8), // Light Brown
    const Color(0xFFCFD8DC), // Light Grey
    const Color(0xFFB0BEC5), // Light Blue Grey
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
        _databaseRef.child('nail_color').onValue.listen((event) {
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
                "Nail Paint - Start Styling",
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

  // Add shape selection widget
  Widget _buildShapeSelector(bool isDarkMode) {
    final shapes = ['shape', 'almond'];
    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: shapes.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () {
              setState(() => _selectedShape = shapes[index]);
              _databaseRef.child('nail_color').update({'shape': shapes[index]});
            },
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 8),
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _selectedShape == shapes[index]
                    ? Colors.white.withOpacity(0.3)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  shapes[index].toUpperCase(),
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.white,
                    fontWeight: _selectedShape == shapes[index]
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        },
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
          _buildShapeSelector(isDarkMode), // Add shape selector here
          const SizedBox(height: 8),
          _buildNailLengthSlider(isDarkMode), // Add length slider here
          const SizedBox(height: 8),
          _buildActionButtons(isDarkMode, textColor),
        ],
      ),
    );
  }

  // Nail length slider
  Widget _buildNailLengthSlider(bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Row(
        children: [
          Icon(Icons.zoom_out_map,
              color: isDarkMode ? Colors.white : Colors.black),
          Expanded(
            child: Slider(
              value: _nailLength,
              min: 0.5,
              max: 2.0,
              onChanged: (value) {
                setState(() => _nailLength = value);
                _databaseRef.child('nail_color').update({'length': value});
              },
            ),
          ),
          Text(
            '${_nailLength.toStringAsFixed(1)}x',
            style: TextStyle(
              color: isDarkMode ? Colors.white : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorOptions(bool isDarkMode) {
    return SizedBox(
      height: 70,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _nailColors.length,
        itemBuilder: (context, index) {
          final colorHex =
              _nailColors[index].value.toRadixString(16).substring(2);
          return GestureDetector(
            onTap: () => _selectColor(colorHex),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: _nailColors[index],
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
                _databaseRef.child('nail_color').update({'opacity': value});
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
              iconPath: 'assets/images/end_session.png',
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
      await _databaseRef.child('nail_color').update({
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

    _databaseRef.child('nail_color').update({'color': null});

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
          'POST', Uri.parse('http://192.168.160.206:5000/detect_nails'));

      // Add information about camera direction to help server process correctly
      request.fields['camera_direction'] = _currentCameraDirection.toString();

      request.files.add(http.MultipartFile.fromBytes(
        'image',
        imageBytes,
        filename: 'nails.jpg',
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
          final snapshot = await _databaseRef.child('nail_color').get();
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
