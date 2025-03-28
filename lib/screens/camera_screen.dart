import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:io';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  bool _isInitialized = false;
  bool _isTakingPicture = false;
  XFile? _capturedImage;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) return;

    _controller = CameraController(
      cameras[0],
      ResolutionPreset.high,
      enableAudio: false,
    );

    try {
      await _controller!.initialize();
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      print('Error initializing camera: $e');
    }
  }

  Future<void> _takePicture() async {
    if (_controller == null || !_controller!.value.isInitialized || _isTakingPicture) {
      return;
    }

    setState(() {
      _isTakingPicture = true;
    });

    try {
      final XFile image = await _controller!.takePicture();
      setState(() {
        _capturedImage = image;
        _isTakingPicture = false;
      });
    } catch (e) {
      print('Error taking picture: $e');
      setState(() {
        _isTakingPicture = false;
      });
    }
  }

  void _resetCamera() {
    setState(() {
      _capturedImage = null;
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_capturedImage != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Photo Preview'),
          backgroundColor: Colors.black,
        ),
        body: Stack(
          children: [
            Image.file(
              File(_capturedImage!.path),
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.contain,
            ),
            Positioned(
              bottom: 30,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: _resetCamera,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Retake'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      // Return the image path to the caller
                      Navigator.pop(context, _capturedImage!.path);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Use Photo'),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          // Camera preview
          CameraPreview(_controller!),
          
          // Camera controls
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Close button
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 30),
                  onPressed: () => Navigator.pop(context),
                ),
                
                // Capture button
                GestureDetector(
                  onTap: _takePicture,
                  child: Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.8),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                    ),
                    child: _isTakingPicture
                        ? const CircularProgressIndicator()
                        : Container(),
                  ),
                ),
                
                // Switch camera button
                IconButton(
                  icon: const Icon(Icons.flip_camera_ios, color: Colors.white, size: 30),
                  onPressed: () async {
                    final cameras = await availableCameras();
                    if (cameras.length < 2) return;
                    
                    final currentCamera = _controller!.description;
                    CameraDescription newCamera;
                    
                    if (currentCamera == cameras[0]) {
                      newCamera = cameras[1];
                    } else {
                      newCamera = cameras[0];
                    }
                    
                    await _controller!.dispose();
                    
                    _controller = CameraController(
                      newCamera,
                      ResolutionPreset.high,
                      enableAudio: false,
                    );
                    
                    try {
                      await _controller!.initialize();
                      if (mounted) {
                        setState(() {});
                      }
                    } catch (e) {
                      print('Error switching camera: $e');
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 