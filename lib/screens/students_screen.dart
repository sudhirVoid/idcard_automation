import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:idcard_automation/models/student_model.dart';
import 'package:idcard_automation/screens/camera_screen.dart';
import 'package:idcard_automation/services/excel_service.dart';
import 'package:idcard_automation/services/firestore_service.dart';

class StudentsScreen extends StatefulWidget {
  final String className;
  final String sectionName;

  const StudentsScreen({
    super.key,
    required this.className,
    required this.sectionName,
  });

  @override
  State<StudentsScreen> createState() => _StudentsScreenState();
}

class _StudentsScreenState extends State<StudentsScreen> {
  final ExcelService _excelService = ExcelService();
  final FirestoreService _firestoreService = FirestoreService();
  List<Student> _students = [];
  bool _isLoading = true;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    setState(() => _isLoading = true);
    
    try {
      final studentsData = await _firestoreService.getStudents(
        className: widget.className,
        sectionName: widget.sectionName,
      );

      setState(() {
        _students = studentsData
            .map((data) => Student.fromFirestore(data, data['id']))
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading students: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _uploadExcel() async {
    try {
      // Pick Excel file
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
      );

      if (result == null) return;

      setState(() => _isUploading = true);

      File file = File(result.files.single.path!);

      // Parse Excel file
      final students = await _excelService.parseExcelFile(file);

      if (students.isEmpty) {
        throw Exception('No valid student data found in Excel file');
      }

      // Use all students from Excel (no filtering by class/section)
      final filteredStudents = students;

      // Upload to Firestore (clears existing data)
      final count = await _firestoreService.uploadStudentsToFirestore(
        students: filteredStudents,
        className: widget.className,
        sectionName: widget.sectionName,
        clearExisting: true, // Clear old data
      );

      // Reload students
      await _loadStudents();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully uploaded $count students'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  Future<void> _takePhoto(Student student) async {
    final imageUrl = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => CameraScreen(
          studentId: student.id,
          className: widget.className,
          sectionName: widget.sectionName,
          studentName: student.name,    // ⭐ Real name from Firestore
          rollNo: student.rollNo,       // ⭐ Real roll number from Firestore
        ),
      ),
    );

    if (imageUrl != null) {
      try {
        // Update Firestore
        await _firestoreService.updateStudentPhoto(
          className: widget.className,
          sectionName: widget.sectionName,
          studentId: student.id,
          photoUrl: imageUrl,
        );

        // Update local state
        setState(() {
          student.photoUrl = imageUrl;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Photo updated for ${student.name}'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to save photo: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Widget _buildUploadWidget() {
    return Center(
      child: Card(
        elevation: 4,
        margin: const EdgeInsets.all(24),
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.upload_file, size: 64, color: Colors.deepPurple[200]),
              const SizedBox(height: 16),
              const Text(
                'Upload Student Data',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Upload Excel file for ${widget.className} - ${widget.sectionName}',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
              const SizedBox(height: 8),
              Text(
                'Note: This will replace existing data',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.orange[700]),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _isUploading ? null : _uploadExcel,
                icon: _isUploading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.cloud_upload),
                label: Text(_isUploading ? 'Uploading...' : 'Choose Excel File'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStudentCard(Student student) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      elevation: 2.0,
      child: ListTile(
        leading: CircleAvatar(
          radius: 25,
          backgroundImage: student.photoUrl != null
              ? NetworkImage(student.photoUrl!)
              : null,
          backgroundColor: Colors.grey[300],
          child: student.photoUrl == null
              ? Icon(Icons.person, color: Colors.grey[600])
              : null,
        ),
        title: Text(
          student.name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('Roll No: ${student.rollNo}'),
            if (student.address != null && student.address!.isNotEmpty)
              Text('Address: ${student.address}', 
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            if (student.parentName != null && student.parentName!.isNotEmpty)
              Text('Parent: ${student.parentName}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
          ],
        ),
        trailing: IconButton(
          icon: Icon(
            Icons.camera_alt,
            color: student.photoUrl != null ? Colors.green : Colors.deepPurple,
            size: 28,
          ),
          onPressed: () => _takePhoto(student),
          tooltip: student.photoUrl != null ? 'Update Photo' : 'Take Photo',
        ),
        isThreeLine: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.className} - ${widget.sectionName}'),
        actions: [
          if (_students.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadStudents,
              tooltip: 'Refresh',
            ),
          if (_students.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.upload_file),
              onPressed: _isUploading ? null : _uploadExcel,
              tooltip: 'Re-upload Excel',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _students.isEmpty
              ? _buildUploadWidget()
              : Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      color: Colors.deepPurple[50],
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total Students: ${_students.length}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'With Photos: ${_students.where((s) => s.photoUrl != null).length}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _students.length,
                        itemBuilder: (context, index) {
                          return _buildStudentCard(_students[index]);
                        },
                      ),
                    ),
                  ],
                ),
    );
  }
}
