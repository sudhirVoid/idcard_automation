import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get current user's school name from Firestore
  Future<String?> getSchoolName() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return null;

      final userDoc = await _firestore
          .collection('users')
          .doc(userId)
          .get();

      return userDoc.data()?['name'] as String?;
    } catch (e) {
      throw Exception('Failed to get school name: $e');
    }
  }

  /// Get all classes for current user
  Future<List<String>> getClasses() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not logged in');

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

  /// Add a new class
  Future<void> addClass(String className) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not logged in');

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('classes')
          .doc(className)
          .set({
        'name': className,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to add class: $e');
    }
  }

  /// Get all sections for a class
  Future<List<String>> getSections(String className) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not logged in');

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

  /// Add a new section to a class
  Future<void> addSection(String className, String sectionName) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not logged in');

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('classes')
          .doc(className)
          .collection('sections')
          .doc(sectionName)
          .set({
        'name': sectionName,
        'className': className,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to add section: $e');
    }
  }

  /// Get all students for a specific section
  Future<List<Map<String, dynamic>>> getStudents({
    required String className,
    required String sectionName,
  }) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not logged in');

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

  /// Add a new student to a section
  Future<void> addStudent({
    required String className,
    required String sectionName,
    required String studentName,
    required String rollNo,
    String? address,
    String? parentName,
    String? contactNumber,
    String? busRoute,
  }) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not logged in');

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('classes')
          .doc(className)
          .collection('sections')
          .doc(sectionName)
          .collection('students')
          .add({
        'name': studentName,
        'rollNo': rollNo,
        'className': className,
        'section': sectionName,
        'address': address,
        'parentName': parentName,
        'contactNumber': contactNumber,
        'busRoute': busRoute,
        'photoUrl': null,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to add student: $e');
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
      if (userId == null) throw Exception('User not logged in');

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

  /// Upload multiple students to a section (from Excel)
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
        // Handle default section
        final sectionName = student['section'] ?? 'Default';
        
        // Create new student document
        final studentRef = sectionRef.collection('students').doc();
        
        batch.set(studentRef, {
          'name': student['name'],
          'rollNo': student['rollNo'],
          'className': student['className'],
          'section': sectionName,
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
}
