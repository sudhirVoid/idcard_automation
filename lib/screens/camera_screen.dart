import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:idcard_automation/screens/image_crop_screen.dart';
import 'package:idcard_automation/services/cloudinary_service.dart';

class CameraScreen extends StatefulWidget {
  final String? studentId;
  final String? className;
  final String? sectionName;
  final String? studentName;
  final String? rollNo;
  
  const CameraScreen({
    super.key,
    this.studentId,
    this.className,
    this.sectionName,
    this.studentName,
    this.rollNo,
  });

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  late Future<void> _initializeControllerFuture;

  @override
  void initState() {
    super.initState();
    _initializeControllerFuture = _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    final firstCamera = cameras.firstWhere(
          (camera) => camera.lensDirection == CameraLensDirection.back,
    );

    _controller = CameraController(
      firstCamera,
      ResolutionPreset.medium,
    );

    await _controller!.initialize();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _takePicture() async {
    try {
      await _initializeControllerFuture;

      // Take the picture
      final image = await _controller!.takePicture();

      if (!mounted) return;

      // Navigate to crop screen
      final croppedImagePath = await Navigator.push<String>(
        context,
        MaterialPageRoute(
          builder: (context) => ImageCropScreen(imagePath: image.path),
        ),
      );

      if (croppedImagePath == null || !mounted) {
        return; // User cancelled cropping
      }

      // Show loading dialog while uploading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Uploading image...'),
                ],
              ),
            ),
          ),
        ),
      );

      try {
        // Get school name from Firestore
        final userId = FirebaseAuth.instance.currentUser?.uid;
        if (userId == null) throw Exception('User not logged in');

        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .get();

        final schoolName = userDoc.data()?['name'] ?? 'default_school';
        final className = widget.className ?? 'default_class';
        final sectionName = widget.sectionName ?? 'default_section';
        final studentId = widget.studentId ?? 'student_${DateTime.now().millisecondsSinceEpoch}';
        final studentName = widget.studentName ?? 'student';
        final rollNo = widget.rollNo ?? studentId;

        // Upload to Cloudinary with folder structure: idcard/schoolName/class/section/
        // Filename: Class_Section_RollNo_StudentName.jpg
        final cloudinaryService = CloudinaryService();
        final imageUrl = await cloudinaryService.uploadImage(
          imageFile: File(croppedImagePath),
          schoolName: schoolName,
          className: className,
          sectionName: sectionName,
          studentId: studentId,
          studentName: studentName,
          rollNo: rollNo,
        );

        if (mounted) {
          Navigator.pop(context); // Close loading dialog
          Navigator.pop(context, imageUrl); // Return image URL
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Image uploaded successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          Navigator.pop(context); // Close loading dialog
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Upload failed: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error taking picture: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Take a picture')),
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done &&
              _controller != null) {
            return CameraPreview(_controller!);
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _takePicture,
        child: const Icon(Icons.camera_alt),
      ),
    );
  }
}
