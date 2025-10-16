import 'dart:io';
import 'package:excel/excel.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ExcelService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Parse Excel file and extract student data
  /// Expected Excel format with flexible column order:
  /// Headers: Class, Section, Name, Address, Parents, Contact, Bus
  /// Additional columns like S.N, N are ignored
  Future<List<Map<String, dynamic>>> parseExcelFile(File file) async {
    try {
      var bytes = file.readAsBytesSync();
      var excel = Excel.decodeBytes(bytes);

      List<Map<String, dynamic>> students = [];

      // Get first sheet
      var sheet = excel.tables[excel.tables.keys.first];
      
      if (sheet == null || sheet.rows.isEmpty) {
        throw Exception('Excel file is empty');
      }

      // Get header row (first row)
      var headerRow = sheet.rows[0];
      if (headerRow.isEmpty) {
        throw Exception('Excel file has no headers');
      }

      // Map column headers to their indices
      Map<String, int> columnMap = {};
      for (int i = 0; i < headerRow.length; i++) {
        var header = headerRow[i]?.value?.toString().trim().toLowerCase();
        if (header != null && header.isNotEmpty) {
          // Map various possible header names to our standard names
          switch (header) {
            case 'class':
            case 'grade':
            case 'standard':
              columnMap['class'] = i;
              break;
            case 'section':
            case 'division':
              columnMap['section'] = i;
              break;
            case 'name':
            case 'student name':
            case 'student_name':
              columnMap['name'] = i;
              break;
            case 'address':
              columnMap['address'] = i;
              break;
            case 'parents':
            case 'parent':
            case 'parent name':
            case 'parent_name':
              columnMap['parents'] = i;
              break;
            case 'contact':
            case 'phone':
            case 'mobile':
            case 'contact number':
            case 'contact_number':
              columnMap['contact'] = i;
              break;
            case 'bus':
            case 'bus route':
            case 'bus_route':
              columnMap['bus'] = i;
              break;
            case 's.n':
            case 's.n.':
            case 'serial no':
            case 'serial_no':
            case 'roll no':
            case 'roll_no':
            case 'roll number':
            case 'roll_number':
              columnMap['rollno'] = i;
              break;
          }
        }
      }

      // Validate required columns
      if (!columnMap.containsKey('class')) {
        throw Exception('Required column "Class" not found in Excel file');
      }
      if (!columnMap.containsKey('name')) {
        throw Exception('Required column "Name" not found in Excel file');
      }
      // Note: Section is optional - will default to "Default" if not found

      print('Column mapping found: $columnMap');

      // Process data rows (skip header row)
      for (var i = 1; i < sheet.rows.length; i++) {
        var row = sheet.rows[i];
        
        // Skip empty rows
        if (row.isEmpty || row.every((cell) => cell?.value == null)) {
          continue;
        }

        // Extract data using column mapping
        final className = _getCellValue(row, columnMap['class']);
        final section = _getCellValue(row, columnMap['section']);
        final name = _getCellValue(row, columnMap['name']);
        final address = _getCellValue(row, columnMap['address']);
        final parentName = _getCellValue(row, columnMap['parents']);
        final contact = _getCellValue(row, columnMap['contact']);
        final busRoute = _getCellValue(row, columnMap['bus']);
        final rollNo = _getCellValue(row, columnMap['rollno']);

        // Handle default section - if section is empty, use "Default"
        final finalSection = section.isEmpty ? 'Default' : section;

        // Validate required fields (Class and Name are required, Section defaults to "Default")
        if (className.isEmpty || name.isEmpty) {
          print('Skipping row ${i + 1}: Missing required data (Class or Name)');
          continue;
        }

        // Use provided roll number or generate from row index
        final finalRollNo = rollNo.isNotEmpty ? rollNo : '${i}';

        students.add({
          'rollNo': finalRollNo,
          'className': className,
          'section': finalSection,
          'name': name,
          'address': address.isNotEmpty ? address : null,
          'parentName': parentName.isNotEmpty ? parentName : null,
          'contactNumber': contact.isNotEmpty ? contact : null,
          'busRoute': busRoute.isNotEmpty ? busRoute : null,
        });
      }

      return students;
    } catch (e) {
      throw Exception('Failed to parse Excel file: $e');
    }
  }

  /// Helper method to safely get cell value by column index
  String _getCellValue(List<dynamic> row, int? columnIndex) {
    if (columnIndex == null || columnIndex >= row.length) {
      return '';
    }
    return row[columnIndex]?.value?.toString().trim() ?? '';
  }

  /// Upload students to Firestore
  /// Structure: users/{userId}/classes/{className}/sections/{sectionName}/students/{studentId}
  /// If clearExisting is true, deletes all existing students in that section first
  Future<int> uploadStudentsToFirestore({
    required List<Map<String, dynamic>> students,
    required String className,
    required String sectionName,
    bool clearExisting = true,
  }) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not logged in');
      }

      // Reference to section document
      final sectionRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('classes')
          .doc(className)
          .collection('sections')
          .doc(sectionName);

      // Clear existing students if requested
      if (clearExisting) {
        await _clearExistingStudents(sectionRef);
      }

      // Batch write for better performance
      WriteBatch batch = _firestore.batch();
      int count = 0;

      for (var student in students) {
        // Create new student document
        final studentRef = sectionRef.collection('students').doc();
        
        batch.set(studentRef, {
          'name': student['name'],
          'rollNo': student['rollNo'],
          'className': student['className'],
          'section': student['section'],
          'address': student['address'],
          'parentName': student['parentName'],
          'contactNumber': student['contactNumber'],
          'busRoute': student['busRoute'],
          'photoUrl': null,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        
        count++;

        // Commit batch every 500 operations (Firestore limit)
        if (count % 500 == 0) {
          await batch.commit();
          batch = _firestore.batch();
        }
      }

      // Commit remaining operations
      if (count % 500 != 0) {
        await batch.commit();
      }

      // Update section metadata
      await sectionRef.set({
        'className': className,
        'sectionName': sectionName,
        'studentCount': count,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      return count;
    } catch (e) {
      throw Exception('Failed to upload to Firestore: $e');
    }
  }

  /// Clear all existing students in a section
  Future<void> _clearExistingStudents(DocumentReference sectionRef) async {
    try {
      // Get all students
      final studentsSnapshot = await sectionRef.collection('students').get();

      if (studentsSnapshot.docs.isEmpty) {
        return; // Nothing to delete
      }

      // Delete in batches
      WriteBatch batch = _firestore.batch();
      int count = 0;

      for (var doc in studentsSnapshot.docs) {
        batch.delete(doc.reference);
        count++;

        if (count % 500 == 0) {
          await batch.commit();
          batch = _firestore.batch();
        }
      }

      // Commit remaining deletions
      if (count % 500 != 0) {
        await batch.commit();
      }

      print('Cleared $count existing students');
    } catch (e) {
      throw Exception('Failed to clear existing students: $e');
    }
  }

  /// Get all students for a specific section
  Future<List<Map<String, dynamic>>> getStudents({
    required String className,
    required String sectionName,
  }) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not logged in');
      }

      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('classes')
          .doc(className)
          .collection('sections')
          .doc(sectionName)
          .collection('students')
          .orderBy('rollNo')
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      throw Exception('Failed to get students: $e');
    }
  }

  /// Get all classes for current user
  Future<List<String>> getClasses() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not logged in');
      }

      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('classes')
          .get();

      return snapshot.docs.map((doc) => doc.id).toList();
    } catch (e) {
      throw Exception('Failed to get classes: $e');
    }
  }

  /// Get all sections for a class
  Future<List<String>> getSections(String className) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not logged in');
      }

      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('classes')
          .doc(className)
          .collection('sections')
          .get();

      return snapshot.docs.map((doc) => doc.id).toList();
    } catch (e) {
      throw Exception('Failed to get sections: $e');
    }
  }

  /// Update student photo URL
  Future<void> updateStudentPhoto({
    required String className,
    required String sectionName,
    required String studentId,
    required String photoUrl,
  }) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not logged in');
      }

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('classes')
          .doc(className)
          .collection('sections')
          .doc(sectionName)
          .collection('students')
          .doc(studentId)
          .update({
        'photoUrl': photoUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update student photo: $e');
    }
  }
}

