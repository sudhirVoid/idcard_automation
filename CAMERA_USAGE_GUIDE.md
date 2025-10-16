# 📸 Camera Screen Usage Guide

## Folder Structure

Images are uploaded to Cloudinary following this structure:

```
cloudinary/
  └── idcard/
      └── {schoolName}/
          └── {className}/
              └── {sectionName}/
                  └── {studentId}/
                      └── photo_timestamp.jpg
```

**Example:**
```
cloudinary/
  └── idcard/
      └── greenwood_high_school/
          └── grade_10/
              └── section_a/
                  └── student_12345/
                      └── photo_1698765432.jpg
```

---

## Usage in Your Code

### Basic Usage (with all parameters)

```dart
// Navigate to camera screen with all parameters
final imageUrl = await Navigator.push<String>(
  context,
  MaterialPageRoute(
    builder: (context) => CameraScreen(
      studentId: 'student_12345',
      className: 'Grade 10',
      sectionName: 'Section A',
    ),
  ),
);

if (imageUrl != null) {
  print('Image uploaded successfully: $imageUrl');
  // Save the imageUrl to Firestore with student data
}
```

### Usage from Students Screen

```dart
// In your students_screen.dart
onTap: () async {
  final imageUrl = await Navigator.push<String>(
    context,
    MaterialPageRoute(
      builder: (context) => CameraScreen(
        studentId: student.id,          // From your student model
        className: widget.className,     // Passed from class screen
        sectionName: widget.sectionName, // Passed from section screen
      ),
    ),
  );
  
  if (imageUrl != null) {
    // Update student photo URL in Firestore
    await FirebaseFirestore.instance
        .collection('students')
        .doc(student.id)
        .update({'photoUrl': imageUrl});
    
    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Photo uploaded successfully!')),
    );
  }
}
```

---

## Default Values

If you don't provide parameters, default values will be used:

| Parameter | Default Value | When to Use |
|-----------|---------------|-------------|
| `studentId` | `student_timestamp` | Testing or temporary uploads |
| `className` | `default_class` | Testing only |
| `sectionName` | `default_section` | Testing only |

**⚠️ Important:** Always provide all parameters in production!

---

## Complete Flow Example

### 1. Schools Screen → Classes Screen
```dart
// schools_screen.dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => ClassesScreen(
      school: school,
    ),
  ),
);
```

### 2. Classes Screen → Sections Screen
```dart
// classes_screen.dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => SectionsScreen(
      className: classItem.name,  // Pass class name
    ),
  ),
);
```

### 3. Sections Screen → Students Screen
```dart
// sections_screen.dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => StudentsScreen(
      className: widget.className,      // Pass through
      sectionName: section.name,        // Pass section name
    ),
  ),
);
```

### 4. Students Screen → Camera Screen
```dart
// students_screen.dart
ElevatedButton.icon(
  onPressed: () async {
    final imageUrl = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => CameraScreen(
          studentId: student.id,
          className: widget.className,
          sectionName: widget.sectionName,
        ),
      ),
    );
    
    if (imageUrl != null) {
      // Update student record
      setState(() {
        student.photoUrl = imageUrl;
      });
      
      // Save to Firestore
      await _saveStudentPhoto(student.id, imageUrl);
    }
  },
  icon: Icon(Icons.camera_alt),
  label: Text('Take Photo'),
)
```

---

## Folder Name Sanitization

The service automatically sanitizes folder names:
- Removes special characters
- Replaces spaces with underscores
- Converts to lowercase
- Removes multiple consecutive underscores

**Examples:**
| Input | Output |
|-------|--------|
| `Greenwood High School` | `greenwood_high_school` |
| `Grade 10-A` | `grade_10_a` |
| `Section (A)` | `section_a` |
| `Student #123` | `student_123` |

---

## Upload Multiple Images

If you need to upload multiple images for one student:

```dart
// Using CloudinaryService directly
final cloudinaryService = CloudinaryService();

List<File> imageFiles = [file1, file2, file3];

final imageUrls = await cloudinaryService.uploadMultipleImages(
  imageFiles: imageFiles,
  schoolName: 'Greenwood High',
  className: 'Grade 10',
  sectionName: 'Section A',
  studentId: 'student_12345',
);

print('Uploaded ${imageUrls.length} images');
```

---

## Testing the Camera

### Quick Test (Without Navigation Flow)

```dart
// Any screen - for testing only
ElevatedButton(
  onPressed: () async {
    final imageUrl = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => CameraScreen(
          studentId: 'test_student',
          className: 'Test Class',
          sectionName: 'Test Section',
        ),
      ),
    );
    
    if (imageUrl != null) {
      print('Test upload successful: $imageUrl');
    }
  },
  child: Text('Test Camera'),
)
```

---

## Cloudinary Result

After successful upload, the image will be:

1. **Stored at:**
   ```
   https://res.cloudinary.com/dyoydiz81/image/upload/
   idcard/schoolname/classname/sectionname/studentid/filename.jpg
   ```

2. **Accessible via returned URL:**
   ```dart
   // Example URL
   https://res.cloudinary.com/dyoydiz81/image/upload/v1234567890/
   idcard/greenwood_high_school/grade_10/section_a/student_12345/image.jpg
   ```

3. **In Cloudinary Dashboard:**
   - Navigate to Media Library
   - You'll see a base **idcard** folder
   - Inside: folders organized by school → class → section → student

---

## Error Handling

The camera screen handles these errors automatically:

| Error | What Happens |
|-------|--------------|
| User not logged in | Shows error, doesn't upload |
| Camera permission denied | Shows error message |
| User cancels crop | Returns to previous screen |
| Upload fails | Shows error snackbar, stays on screen |
| No internet | Shows upload failed message |

---

## Best Practices

### ✅ Do:
- Always pass all three parameters (studentId, className, sectionName)
- Use meaningful IDs and names
- Check if imageUrl is not null before using
- Save the imageUrl to your database immediately
- Show loading indicator while uploading

### ❌ Don't:
- Use special characters in parameters
- Rely on default values in production
- Navigate away before upload completes
- Forget to handle null return value

---

## Complete Example: Add Photo Button to Student Card

```dart
class StudentCard extends StatefulWidget {
  final Student student;
  final String className;
  final String sectionName;
  
  const StudentCard({
    required this.student,
    required this.className,
    required this.sectionName,
  });

  @override
  State<StudentCard> createState() => _StudentCardState();
}

class _StudentCardState extends State<StudentCard> {
  bool _isUploading = false;
  
  Future<void> _takePhoto() async {
    setState(() => _isUploading = true);
    
    try {
      final imageUrl = await Navigator.push<String>(
        context,
        MaterialPageRoute(
          builder: (context) => CameraScreen(
            studentId: widget.student.id,
            className: widget.className,
            sectionName: widget.sectionName,
          ),
        ),
      );
      
      if (imageUrl != null) {
        // Update Firestore
        await FirebaseFirestore.instance
            .collection('students')
            .doc(widget.student.id)
            .update({'photoUrl': imageUrl});
        
        // Update local state
        setState(() {
          widget.student.photoUrl = imageUrl;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Photo updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: widget.student.photoUrl != null
              ? NetworkImage(widget.student.photoUrl!)
              : null,
          child: widget.student.photoUrl == null
              ? Icon(Icons.person)
              : null,
        ),
        title: Text(widget.student.name),
        subtitle: Text('ID: ${widget.student.id}'),
        trailing: _isUploading
            ? CircularProgressIndicator()
            : IconButton(
                icon: Icon(Icons.camera_alt),
                onPressed: _takePhoto,
              ),
      ),
    );
  }
}
```

---

## Folder Structure Verification

To verify your uploads in Cloudinary:

1. Go to: https://console.cloudinary.com/console/media_library
2. You should see folders like:
   ```
   📁 idcard
      📁 greenwood_high_school
         📁 grade_10
            📁 section_a
               📁 student_12345
                  📷 image.jpg
   ```

---

## Troubleshooting

### Upload fails with "Missing required parameter"
- Check all parameters are being passed
- Verify Cloudinary credentials are correct

### Folder not created properly
- Check parameter values aren't null
- Verify school name in user's Firestore document

### Image shows in wrong folder
- Verify you're passing correct className and sectionName
- Check the parameters throughout the navigation flow

---

Happy coding! 📸

