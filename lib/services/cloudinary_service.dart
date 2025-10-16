import 'dart:io';
import 'package:cloudinary_public/cloudinary_public.dart';

class CloudinaryService {
  static const String cloudName = 'dyoydiz81'; // Replace with your Cloudinary cloud name
  static const String uploadPreset = 'idcard'; // Replace with your upload preset

  final cloudinary = CloudinaryPublic(cloudName, uploadPreset);

  /// Upload image to Cloudinary with folder structure: idcard/schoolName/class/section/
  /// Filename format: Class_Section_RollNo_StudentName.jpg
  /// Returns the secure URL of the uploaded image
  /// Note: Uses fixed filename format, so new uploads will OVERWRITE old ones
  Future<String> uploadImage({
    required File imageFile,
    required String schoolName,
    required String className,
    required String sectionName,
    required String studentId,
    String? studentName,
    String? rollNo,
  }) async {
    try {
      // Create folder structure: idcard/schoolName/class/section
      final folderPath = 'idcard/'
          '${_sanitizeFolderName(schoolName)}/'
          '${_sanitizeFolderName(className)}/'
          '${_sanitizeFolderName(sectionName)}';

      // Create filename: Class_Section_RollNo_StudentName
      final sanitizedClass = _sanitizeFolderName(className);
      final sanitizedSection = _sanitizeFolderName(sectionName);
      final sanitizedRollNo = rollNo != null ? _sanitizeFolderName(rollNo) : studentId;
      final sanitizedName = studentName != null ? _sanitizeFolderName(studentName) : 'student';
      
      final fileName = '${sanitizedClass}_${sanitizedSection}_${sanitizedRollNo}_${sanitizedName}';

      CloudinaryResponse response = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          imageFile.path,
          folder: folderPath,
          publicId: fileName, // This ensures overwrite with consistent naming
          resourceType: CloudinaryResourceType.Image,
        ),
      );

      return response.secureUrl;
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  /// Upload multiple images for a student
  Future<List<String>> uploadMultipleImages({
    required List<File> imageFiles,
    required String schoolName,
    required String className,
    required String sectionName,
    required String studentId,
    String? studentName,
    String? rollNo,
  }) async {
    List<String> uploadedUrls = [];

    for (var imageFile in imageFiles) {
      try {
        final url = await uploadImage(
          imageFile: imageFile,
          schoolName: schoolName,
          className: className,
          sectionName: sectionName,
          studentId: studentId,
          studentName: studentName,
          rollNo: rollNo,
        );
        uploadedUrls.add(url);
      } catch (e) {
        // Continue uploading other images even if one fails
        print('Failed to upload ${imageFile.path}: $e');
      }
    }

    return uploadedUrls;
  }

  /// Delete image from Cloudinary
  /// Note: Deletion requires signed API calls which aren't supported in unsigned mode
  /// You'll need to implement server-side deletion or use Cloudinary dashboard
  Future<void> deleteImage(String publicId) async {
    throw UnimplementedError(
      'Image deletion requires signed API calls. '
      'Please delete images via Cloudinary dashboard or implement server-side deletion.',
    );
  }

  /// Sanitize folder name to remove special characters
  String _sanitizeFolderName(String name) {
    return name
        .replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .toLowerCase();
  }
}

