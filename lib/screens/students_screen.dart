import 'dart:io';

import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:idcard_automation/models/section_model.dart';
import 'package:idcard_automation/models/student_model.dart';
import 'package:idcard_automation/screens/camera_screen.dart';

class StudentsScreen extends StatefulWidget {
  final String schoolName;
  final String className;
  final Section section;

  const StudentsScreen(
      {super.key,
      required this.schoolName,
      required this.className,
      required this.section});

  @override
  State<StudentsScreen> createState() => _StudentsScreenState();
}

class _StudentsScreenState extends State<StudentsScreen> {
  void _navigateToCamera(int studentIndex) async {
    final imagePath = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CameraScreen(),
      ),
    );

    if (imagePath != null) {
      setState(() {
        widget.section.students[studentIndex].imagePath = imagePath;
      });
    }
  }

  void _uploadExcel() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
    );

    if (result != null) {
      File file = File(result.files.single.path!);
      var bytes = file.readAsBytesSync();
      var excel = Excel.decodeBytes(bytes);

      // Use a temporary list to hold the students and prevent multiple setState calls.
      final List<Student> newStudents = [];

      // Only process the first sheet in the Excel file.
      if (excel.tables.keys.isNotEmpty) {
        final String sheetName = excel.tables.keys.first;
        final sheet = excel.tables[sheetName]!;

        // Start from 1 to skip the header row.
        for (var i = 1; i < sheet.rows.length; i++) {
          final row = sheet.rows[i];

          // Skip empty rows by checking the serial number.
          if (row.isEmpty || row[0] == null || row[0]!.value.toString().isEmpty) {
            continue;
          }

          final excelClassName = row[1]?.value.toString();
          final excelSectionName = row[2]?.value.toString();

          // Only add students that match the current class and section.
          // The comparison is case-insensitive and trims whitespace to avoid mismatches.
          if (excelClassName?.trim().toLowerCase() == widget.className.trim().toLowerCase() &&
              excelSectionName?.trim().toLowerCase() == widget.section.name.trim().toLowerCase()) {
            final student = Student(
              name: row[3]?.value.toString() ?? '',
              address: row[4]?.value.toString() ?? '',
              parentName: row[5]?.value.toString() ?? '',
              contactNumber: row[6]?.value.toString() ?? '',
              busRoute: row[7]?.value.toString() ?? '',
            );
            newStudents.add(student);
          }
        }
      }

      // Update the state once with the new list of students.
      // Clearing the list first ensures that re-uploading a file replaces the old data.
      setState(() {
        widget.section.students.clear();
        widget.section.students.addAll(newStudents);
      });
    }
  }

  Widget _buildUploadWidget() {
    return Center(
      child: Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.upload_file, size: 64, color: Colors.grey[600]),
              const SizedBox(height: 16),
              const Text(
                'Upload Student Data',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Select an Excel file for this section.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _uploadExcel,
                icon: const Icon(Icons.cloud_upload_outlined),
                label: const Text('Choose File'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            'Students in ${widget.section.name} - ${widget.className} - ${widget.schoolName}'),
      ),
      body: widget.section.students.isEmpty
          ? _buildUploadWidget()
          : ListView.builder(
              itemCount: widget.section.students.length,
              itemBuilder: (context, index) {
                final student = widget.section.students[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 8.0),
                  elevation: 2.0,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        student.imagePath != null
                            ? CircleAvatar(
                                backgroundImage:
                                    FileImage(File(student.imagePath!)),
                                radius: 30,
                              )
                            : const CircleAvatar(
                                radius: 30,
                                child: Icon(Icons.person, size: 30),
                              ),
                        const SizedBox(width: 16.0),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(student.name,
                                  style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8.0),
                              Text('Address: ${student.address}'),
                              const SizedBox(height: 4.0),
                              Text('Parent: ${student.parentName}'),
                              const SizedBox(height: 4.0),
                              Text('Contact: ${student.contactNumber}'),
                              const SizedBox(height: 4.0),
                              Text('Bus Route: ${student.busRoute}'),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.camera_alt_outlined,
                              color: Colors.deepPurple, size: 30),
                          tooltip: 'Take Photo',
                          onPressed: () => _navigateToCamera(index),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
