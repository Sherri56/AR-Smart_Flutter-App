import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'theme_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:typed_data';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/services.dart';

class EyeBrowPage extends StatefulWidget {
  const EyeBrowPage({super.key});

  @override
  _EyeBrowPageState createState() => _EyeBrowPageState();
}

class _EyeBrowPageState extends State<EyeBrowPage> {
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  bool _isCameraInitialized = false;
  bool _hasPermission = false;
  Timer? _detectionTimer;
  bool _isDetecting = false;
  bool _isProcessing = false;
  String _selectedShape = 'natural';
  double _opacity = 0.8; // New opacity control
  Uint8List? _processedImage;
  final DatabaseReference _databaseRef = FirebaseDatabase.instance.ref();
  bool _applyOverlay = false;

  // Add camera direction tracking
  CameraLensDirection _currentCameraDirection = CameraLensDirection.front;

  // Server endpoint
  static const String _serverUrl = 'http://192.168.160.206:5000';
  static const String _eyebrowEndpoint = '/detect_eyebrows';

  @override
  void initState() {
    super.initState();
    // Set preferred orientations
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
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

        await _cameraController!.initialize();
        if (mounted) {
          setState(() {
            _isCameraInitialized = true;
          });
          _startDetectionLoop();
        }
      } else {
        print("No cameras available.");
      }
    } catch (e) {
      print("Camera initialization error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Camera error: ${e.toString()}")),
        );
      }
    }
  }

  // Add camera switch function
  Future<void> _switchCamera() async {
    if (_cameras.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No additional cameras available")),
      );
      return;
    }

    setState(() {
      _isCameraInitialized = false;
      _processedImage = null; // Clear current processed image
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
  }

  Future<void> _captureAndSendImage() async {
    if (_isProcessing || !_applyOverlay)
      return; // Only process if overlay enabled

    setState(() => _isProcessing = true);

    try {
      if (!_cameraController!.value.isInitialized) return;

      final XFile file = await _cameraController!.takePicture();
      final imageBytes = await file.readAsBytes();

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_serverUrl$_eyebrowEndpoint'),
      );

      request.files.add(http.MultipartFile.fromBytes(
        'image',
        imageBytes,
        filename: 'eyebrow_input.jpg',
      ));

      // Send current shape and opacity
      request.fields['shape'] = _selectedShape;
      request.fields['opacity'] = _opacity.toString();

      // Add camera direction information
      request.fields['camera_direction'] = _currentCameraDirection.toString();

      final response = await request.send();

      if (response.statusCode == 200) {
        final bytes = await response.stream.toBytes();
        setState(() => _processedImage = bytes);
      }
    } catch (e) {
      print("Error: $e");
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  void _startDetectionLoop() {
    _detectionTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      if (!_isDetecting) {
        _isDetecting = true;
        await _captureAndSendImage();
        _isDetecting = false;
      }
    });
  }

  void _clearSelections() {
    _detectionTimer?.cancel(); // Stop the detection loop

    setState(() {
      _selectedShape = 'natural';
      _processedImage = null;
      _applyOverlay = false;
    });

    _databaseRef.child('eyebrow_settings').update({
      'shape': null,
      'opacity': 0.8,
      'last_updated': DateTime.now().millisecondsSinceEpoch
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Selections cleared!",
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  void _showEndSessionDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Provider.of<ThemeProvider>(context).isDarkMode
              ? Colors.black
              : const Color(0xFFFFC2D1),
          title: const Text(
            "End Session?",
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            "Are you sure you want to end this styling session?",
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

  Widget _buildShapeSelector(bool isDarkMode) {
    final shapes = {
      'natural': 'Natural',
      'straight': 'Straight',
      'soft_angled': 'Soft Angled',
      'high_arch': 'High Arch',
      'thick': 'Thick'
    };

    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: shapes.length,
        itemBuilder: (context, index) {
          final key = shapes.keys.elementAt(index);
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedShape = key;
                _applyOverlay =
                    true; // Enable overlays when any style is selected
              });
              _databaseRef.child('eyebrow_settings').update({
                'shape': key,
                'last_updated': DateTime.now().millisecondsSinceEpoch
              }).then((_) {
                print('Shape updated to: $key');
                // Trigger immediate processing when shape changes
                _captureAndSendImage();
              });
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _selectedShape == key
                    ? Colors.white.withOpacity(0.3)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                border: _selectedShape == key
                    ? Border.all(color: Colors.white, width: 1)
                    : null,
              ),
              child: Text(
                shapes[key]!,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: _selectedShape == key
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildOpacitySlider(bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Text(
            'Opacity: ${_opacity.toStringAsFixed(1)}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          Slider(
            value: _opacity,
            min: 0.3,
            max: 1.0,
            divisions: 7,
            activeColor: Colors.white,
            inactiveColor: Colors.white.withOpacity(0.3),
            onChanged: (value) {
              setState(() => _opacity = value);
              _databaseRef.child('eyebrow_settings').update({
                'opacity': value,
                'last_updated': DateTime.now().millisecondsSinceEpoch
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(bool isDarkMode) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          const SizedBox(width: 10),
          _buildIconWithLabel(
            iconPath: 'assets/images/clear all.svg',
            label: 'CLEAR ALL',
            onTap: _clearSelections,
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
    );
  }

  Widget _buildBottomControls(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          _buildShapeSelector(isDarkMode),
          _buildOpacitySlider(isDarkMode),
          _buildActionButtons(isDarkMode),
        ],
      ),
    );
  }

  Widget _buildIconWithLabel({
    required String iconPath,
    required String label,
    required VoidCallback onTap,
    bool isSvg = true,
    bool isDarkMode = false,
    double iconSize = 40.0,
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
                    color: Colors.white,
                  )
                : Image.asset(
                    iconPath,
                    height: iconSize,
                    width: iconSize,
                    color: Colors.white,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(Icons.broken_image,
                          size: iconSize, color: Colors.white);
                    },
                  ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    // Reset orientation settings
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    _detectionTimer?.cancel();
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    bool isDarkMode = themeProvider.isDarkMode;

    // Determine if camera feed should be mirrored based on camera direction
    final shouldMirror = _currentCameraDirection == CameraLensDirection.front;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Show processed image if available, otherwise show camera preview
          if (_isProcessing)
            const Center(child: CircularProgressIndicator())
          else if (_processedImage != null)
            SizedBox(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
              child: Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..scale(shouldMirror ? -1.0 : 1.0,
                      1.0), // Mirror only if front camera
                child: Image.memory(
                  _processedImage!,
                  fit: BoxFit.cover,
                ),
              ),
            )
          else if (_hasPermission && _isCameraInitialized)
            SizedBox(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
              child: RotatedBox(
                quarterTurns: 1,
                child: Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..scale(shouldMirror ? -1.0 : 1.0, 1.0),
                  child: CameraPreview(_cameraController!),
                ),
              ),
            )
          else if (!_hasPermission)
            Center(
              child: ElevatedButton(
                onPressed: _checkCameraPermission,
                child: const Text("Enable Camera"),
              ),
            )
          else
            const Center(child: CircularProgressIndicator()),

          // Top app bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top,
                left: 16,
                right: 16,
                bottom: 16,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.7),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Text(
                    "Eyebrow - Start Styling",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  // Add camera switch button
                  IconButton(
                    icon:
                        const Icon(Icons.flip_camera_ios, color: Colors.white),
                    onPressed: _isCameraInitialized ? _switchCamera : null,
                  ),
                ],
              ),
            ),
          ),

          // Bottom controls
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildBottomControls(isDarkMode),
          ),
        ],
      ),
    );
  }
}
