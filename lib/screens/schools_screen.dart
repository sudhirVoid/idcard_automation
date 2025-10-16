import 'package:flutter/material.dart';
import 'package:idcard_automation/models/school_model.dart';
import 'package:idcard_automation/screens/classes_screen.dart';
import 'package:idcard_automation/screens/profile_screen.dart';
import 'package:idcard_automation/services/firestore_service.dart';

class SchoolsScreen extends StatefulWidget {
  const SchoolsScreen({super.key});

  @override
  State<SchoolsScreen> createState() => _SchoolsScreenState();
}

class _SchoolsScreenState extends State<SchoolsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  String? _schoolName;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSchoolName();
  }

  Future<void> _loadSchoolName() async {
    try {
      final schoolName = await _firestoreService.getSchoolName();
      setState(() {
        _schoolName = schoolName;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('School'),
          actions: [
            IconButton(
              icon: const Icon(Icons.person),
              tooltip: 'Profile',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProfileScreen(),
                  ),
                );
              },
            ),
          ],
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('School'),
          actions: [
            IconButton(
              icon: const Icon(Icons.person),
              tooltip: 'Profile',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProfileScreen(),
                  ),
                );
              },
            ),
          ],
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 80, color: Colors.red[400]),
              const SizedBox(height: 16),
              Text('Error loading school: $_error', 
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: Colors.red),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadSchoolName,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_schoolName == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('School'),
          actions: [
            IconButton(
              icon: const Icon(Icons.person),
              tooltip: 'Profile',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProfileScreen(),
                  ),
                );
              },
            ),
          ],
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.school_outlined, size: 80, color: Colors.grey[400]),
              const SizedBox(height: 16),
              const Text('School name not found in profile.', 
                style: TextStyle(fontSize: 18, color: Colors.grey)),
              const SizedBox(height: 8),
              const Text('Please contact administrator to set up your school profile.', 
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    // Create a school object with the fetched name
    final school = School(name: _schoolName!, classes: []);

    return Scaffold(
      appBar: AppBar(
        title: Text(_schoolName!),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            tooltip: 'Profile',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProfileScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Card(
          elevation: 4.0,
          margin: const EdgeInsets.all(24.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ClassesScreen(school: school),
                ),
              );
            },
            borderRadius: BorderRadius.circular(12.0),
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.school, size: 80, color: Colors.deepPurple),
                  const SizedBox(height: 16),
                  Text(
                    _schoolName!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap to manage classes',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
