import 'package:flutter/material.dart';
import 'package:idcard_automation/models/class_model.dart' as app_class;
import 'package:idcard_automation/models/school_model.dart';
import 'package:idcard_automation/screens/sections_screen.dart';
import 'package:idcard_automation/services/firestore_service.dart';

class ClassesScreen extends StatefulWidget {
  final School school;
  const ClassesScreen({super.key, required this.school});

  @override
  State<ClassesScreen> createState() => _ClassesScreenState();
}

class _ClassesScreenState extends State<ClassesScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  List<String> _classes = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadClasses();
  }

  Future<void> _loadClasses() async {
    try {
      final classes = await _firestoreService.getClasses();
      setState(() {
        _classes = classes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _addClass() {
    showDialog(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('Add Class'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(hintText: 'Class Name (e.g., 10th)'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (controller.text.isNotEmpty) {
                  try {
                    await _firestoreService.addClass(controller.text);
                    Navigator.pop(context);
                    _loadClasses(); // Reload classes
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to add class: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.school.name),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.school.name),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 80, color: Colors.red[400]),
              const SizedBox(height: 16),
              Text('Error loading classes: $_error', 
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: Colors.red),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadClasses,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.school.name),
      ),
      body: _classes.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.class_outlined, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  const Text('No classes added yet.',
                      style: TextStyle(fontSize: 18, color: Colors.grey)),
                  const SizedBox(height: 8),
                  const Text('Tap the + button to add a new class.',
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: _classes.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16.0,
                mainAxisSpacing: 16.0,
                childAspectRatio: 1.0,
              ),
              itemBuilder: (context, index) {
                final className = _classes[index];
                final currentClass = app_class.Class(name: className, sections: []);
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SectionsScreen(
                          schoolName: widget.school.name,
                          currentClass: currentClass,
                        ),
                      ),
                    );
                  },
                  child: Card(
                    elevation: 4.0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.class_, size: 50, color: Colors.deepPurple),
                        const SizedBox(height: 16),
                        Text(
                          className,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addClass,
        tooltip: 'Add Class',
        child: const Icon(Icons.add),
      ),
    );
  }
}
