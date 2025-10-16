import 'package:flutter/material.dart';
import 'package:idcard_automation/models/class_model.dart' as app_class;
import 'package:idcard_automation/models/section_model.dart';
import 'package:idcard_automation/screens/students_screen.dart';
import 'package:idcard_automation/services/firestore_service.dart';

class SectionsScreen extends StatefulWidget {
  final String schoolName;
  final app_class.Class currentClass;
  const SectionsScreen(
      {super.key, required this.schoolName, required this.currentClass});

  @override
  State<SectionsScreen> createState() => _SectionsScreenState();
}

class _SectionsScreenState extends State<SectionsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  List<String> _sections = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSections();
  }

  Future<void> _loadSections() async {
    try {
      final sections = await _firestoreService.getSections(widget.currentClass.name);
      setState(() {
        _sections = sections;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _addSection() {
    showDialog(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('Add Section'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(hintText: 'Section Name (e.g., A)'),
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
                    await _firestoreService.addSection(widget.currentClass.name, controller.text);
                    Navigator.pop(context);
                    _loadSections(); // Reload sections
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to add section: $e'),
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
          title: Text(widget.currentClass.name),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.currentClass.name),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 80, color: Colors.red[400]),
              const SizedBox(height: 16),
              Text('Error loading sections: $_error', 
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: Colors.red),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadSections,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.currentClass.name),
      ),
      body: _sections.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.view_carousel_outlined,
                      size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  const Text('No sections added yet.',
                      style: TextStyle(fontSize: 18, color: Colors.grey)),
                  const SizedBox(height: 8),
                  const Text('Tap the + button to add a new section.',
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: _sections.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16.0,
                mainAxisSpacing: 16.0,
                childAspectRatio: 1.0,
              ),
              itemBuilder: (context, index) {
                final sectionName = _sections[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => StudentsScreen(
                          className: widget.currentClass.name,
                          sectionName: sectionName,
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
                        Icon(Icons.view_carousel,
                            size: 50, color: Colors.deepPurple),
                        const SizedBox(height: 16),
                        Text(
                          sectionName,
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
        onPressed: _addSection,
        tooltip: 'Add Section',
        child: const Icon(Icons.add),
      ),
    );
  }
}
