import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';

class ImageCropScreen extends StatefulWidget {
  final String imagePath;

  const ImageCropScreen({
    super.key,
    required this.imagePath,
  });

  @override
  State<ImageCropScreen> createState() => _ImageCropScreenState();
}

class _ImageCropScreenState extends State<ImageCropScreen> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _cropImage();
  }

  Future<void> _cropImage() async {
    setState(() => _isLoading = true);

    try {
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: widget.imagePath,
        compressFormat: ImageCompressFormat.jpg,
        compressQuality: 100,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Image',
            toolbarColor: Colors.deepPurple,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false,
            aspectRatioPresets: [
              CropAspectRatioPreset.square,
              CropAspectRatioPreset.ratio3x2,
              CropAspectRatioPreset.original,
              CropAspectRatioPreset.ratio4x3,
              CropAspectRatioPreset.ratio16x9
            ],
          ),
          IOSUiSettings(
            title: 'Crop Image',
            aspectRatioPresets: [
              CropAspectRatioPreset.square,
              CropAspectRatioPreset.ratio3x2,
              CropAspectRatioPreset.original,
              CropAspectRatioPreset.ratio4x3,
              CropAspectRatioPreset.ratio16x9
            ],
          ),
        ],
      );

      setState(() => _isLoading = false);

      if (croppedFile != null && mounted) {
        // Return the cropped image path
        Navigator.of(context).pop(croppedFile.path);
      } else {
        // User cancelled cropping
        if (mounted) {
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error cropping image: $e'),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: _isLoading
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: Colors.white),
                  const SizedBox(height: 16),
                  const Text(
                    'Loading image editor...',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              )
            : const SizedBox.shrink(),
      ),
    );
  }
}

