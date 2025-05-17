import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'dart:convert';
import 'dart:typed_data';
import 'constants.dart';
import 'theme_constants.dart';

class ExpiryDateCheck extends StatefulWidget {
  const ExpiryDateCheck({Key? key}) : super(key: key);

  @override
  State<ExpiryDateCheck> createState() => _ExpiryDateCheckState();
}

class _ExpiryDateCheckState extends State<ExpiryDateCheck> {
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;
  bool _isLoading = false;
  String? _expiryDate;
  String? _error;
  bool _isTapped = false; // Track tap state
  int? bottomHeight = 0;

  // Add these variables to store preview dimensions
  Size? previewSize;
  double? previewWidth;
  double? previewHeight;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  // Modify _initializeCamera to capture dimensions after initialization
  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      final firstCamera = cameras.first;

      _controller = CameraController(
        firstCamera,
        ResolutionPreset.high,
        enableAudio: false,
      );
      
      _initializeControllerFuture = _controller?.initialize();
      await _initializeControllerFuture; // Wait for initialization

      if (mounted) {
        setState(() {
          // Get preview size after camera is initialized
          previewSize = _controller?.value.previewSize;
          previewWidth = previewSize?.width;
          previewHeight = previewSize?.height;
          bottomHeight = 165;
          // bottomHeight = ((previewHeight! - (previewWidth! * 0.9)) / 2).round();
          print('Preview dimensions: ${previewSize?.width} x ${previewSize?.height}');
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error initializing camera: $e';
      });
    }
  }

  Future<void> _captureAndCheckExpiry() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _expiryDate = null;
    });

    try {
      // Capture the image
      final XFile image = await _controller!.takePicture();
      
      // Read image bytes and convert to image
      final Uint8List imageBytes = await image.readAsBytes();
      final img.Image? originalImage = img.decodeImage(imageBytes);
      
      if (originalImage == null) {
        throw Exception('Failed to decode image');
      }

      // Calculate crop dimensions based on the guide box
      final double screenWidth = MediaQuery.of(context).size.width;
      final int originHeight = originalImage.height;
      final int originWidth = originalImage.width;
      final double boxHeight = originWidth * 0.9;
      final double boxWidth = originWidth * 0.9;

      final double xStart = (originWidth - boxWidth) / 2;
      final double yStart = (originHeight - boxHeight) / 2;

      // setState(() {
      //   bottomHeight = yStart.round() + boxHeight.round() + 20;
      // });
      final img.Image croppedImage = img.copyCrop(
        originalImage,
        x: xStart.round(),
        y: yStart.round(),
        width: boxWidth.round(),
        height: boxHeight.round(),
      );
      
      final croppedBytes = Uint8List.fromList(img.encodeJpg(croppedImage));
      
      // Create multipart request
      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/expiry-date-reader'));
      
      // Add cropped file to request
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          croppedBytes,
          filename: 'image.jpg',
        ),
      );

      // Send request
      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      final jsonData = json.decode(responseData);
      print(jsonData);
      if (response.statusCode == 200 && jsonData['success']) {
        setState(() {
          _expiryDate = jsonData['final_date'] ?? 'No date detected';
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = jsonData['error'] ?? 'Failed to process image';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error processing image: $e';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Check Expiry Date',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: ThemeConstants.primaryColor,
      ),      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: _buildCameraPreview(),
              ),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _buildBottomContent(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomContent() {
    if (_error != null) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.error_outline, color: Colors.red),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _error!,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ],
        ),
      );
    }

    if (_expiryDate != null) {
      // Parse and format the date
      DateTime? parsedDate;
      String formattedDate = _expiryDate!;
      try {
        parsedDate = DateTime.parse(_expiryDate!);
        formattedDate = "${parsedDate.day} ${_getMonthName(parsedDate.month)} ${parsedDate.year}";
      } catch (e) {
        // Keep original format if parsing fails
      }

      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: ThemeConstants.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.calendar_today,
                    color: ThemeConstants.primaryColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Expiry Date',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        formattedDate,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context, _expiryDate);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ThemeConstants.primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'OK',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return const SizedBox(height: 0);
  }

  Widget _buildCameraPreview() {
    return FutureBuilder<void>(
      future: _initializeControllerFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (_controller == null || !_controller!.value.isInitialized) {
            return const Center(child: Text('Camera not initialized'));
          }

          final previewRatio = _controller!.value.aspectRatio;
          final scale = previewRatio;

          return Stack(
            alignment: Alignment.center,
            children: [
              // Base layer: Black and white preview
              Transform.scale(
                scale: scale,
                child: Center(
                  child: ColorFiltered(
                    colorFilter: const ColorFilter.matrix([
                      0.2126, 0.7152, 0.0722, 0, 0,
                      0.2126, 0.7152, 0.0722, 0, 0,
                      0.2126, 0.7152, 0.0722, 0, 0,
                      0, 0, 0, 1, 0,
                    ]),
                    child: CameraPreview(_controller!),
                  ),
                ),
              ),
              // Color preview inside box
              ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: SizedBox(
                  width: MediaQuery.of(context).size.width * 0.9,
                  height: MediaQuery.of(context).size.width * 0.9,
                  child: Transform.scale(
                    scale: scale,
                    child: Center(
                      child: CameraPreview(_controller!),
                    ),
                  ),
                ),
              ),
              // Guide box with visual feedback
              GestureDetector(
                onTapDown: _isLoading ? null : (details) {
                  setState(() {
                    _isTapped = true;
                  });
                },
                onTapUp: _isLoading ? null : (details) {
                  setState(() {
                    _isTapped = false;
                  });
                  _captureAndCheckExpiry();
                },
                onTapCancel: () {
                  setState(() {
                    _isTapped = false;
                  });
                },
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.9,
                  height: MediaQuery.of(context).size.width * 0.9,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: ThemeConstants.primaryColor,
                      width: 2.0,
                    ),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Stack(
                    children: [
                      // Blue tint effect when tapped
                      if (_isTapped)
                        Container(
                          decoration: BoxDecoration(
                            color: ThemeConstants.primaryColor.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                      // Loading animation
                      if (_isLoading)
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 50,
                                  height: 50,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 3,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'Reading expiry date...',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              // Help text
              Positioned(
                bottom: bottomHeight!.toDouble(),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    // color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Align medicine strip within the box and tap to scan',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ],
          );
        } else {
          return const Center(child: CircularProgressIndicator());
        }
      },
    );
  }

  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }
}