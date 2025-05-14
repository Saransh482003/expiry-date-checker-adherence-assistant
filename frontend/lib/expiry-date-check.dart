import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:lottie/lottie.dart';
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

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

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
      if (mounted) {
        setState(() {});
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
      final double boxWidth = screenWidth * 0.8;  // Same as in build method
      final double boxHeight = screenWidth * 0.8;
      print('$originalImage.width, $originalImage.height');
      print('$boxWidth, $boxHeight');
      // Calculate crop coordinates based on preview size vs image size ratio
      final previewSize = _controller!.value.previewSize!;
      final double widthRatio = originalImage.width / previewSize.width;
      final double heightRatio = originalImage.height / previewSize.height;
      
      final int startX = (((boxWidth * widthRatio)) / 2).round();
      final int startY = ((originalImage.height - (boxHeight * heightRatio)) / 2).round();
      final int width = (boxWidth).round()*2;
      final int height = (boxHeight * heightRatio).round();

      // Ensure crop dimensions are within image bounds
      final safeStartX = startX.clamp(0, originalImage.width - 1);
      final safeStartY = startY.clamp(0, originalImage.height - 1);
      final safeWidth = width.clamp(1, originalImage.width - safeStartX);
      final safeHeight = height.clamp(1, originalImage.height - safeStartY);

      // Crop image
      final img.Image croppedImage = img.copyCrop(
        originalImage,
        x: safeStartX,
        y: safeStartY,
        width: safeWidth,
        height: safeHeight,
      );

      // Convert cropped image back to bytes
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
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: _buildCameraPreview(),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 100), // Bottom padding for FAB
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
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,                    
                    children: [                      
                      SizedBox(
                        width: 150,
                        height: 150,
                        child: Lottie.asset(
                          'assets/scanning.json',
                          repeat: true,
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Processing image...',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isLoading ? null : _captureAndCheckExpiry,
        backgroundColor: ThemeConstants.primaryColor,
        child: Icon(
          _isLoading ? Icons.hourglass_empty : Icons.camera_alt,
          color: Colors.white,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
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
                style: const TextStyle(
                  color: Colors.red,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (_expiryDate != null) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: ThemeConstants.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.check_circle_outline,
                color: ThemeConstants.primaryColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Detected Expiry Date:',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _expiryDate!,
                    style: const TextStyle(
                      fontSize: 20,
                      color: ThemeConstants.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
          return Stack(
            alignment: Alignment.center,
            children: [
              CameraPreview(_controller!),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: ThemeConstants.primaryColor,
                    width: 2.0,
                  ),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                width: MediaQuery.of(context).size.width * 0.8,
                height: MediaQuery.of(context).size.width * 0.8,
              ),
              Positioned(
                bottom: 100,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Align medicine strip within the box',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
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
}