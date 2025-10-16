# 📝 Photo Filename Format

## Format: `Class_Section_RollNo_StudentName.jpg`

All uploaded student photos follow this naming convention for consistency and easy identification.

---

## Examples

### **Example 1:**
```
Input:
- Class: Grade 10
- Section: A
- Roll No: 25
- Student Name: John Doe

Output Filename:
grade_10_a_25_john_doe.jpg
```

### **Example 2:**
```
Input:
- Class: Class 12-B
- Section: Section C
- Roll No: 03
- Student Name: Sarah Smith

Output Filename:
class_12_b_section_c_03_sarah_smith.jpg
```

### **Example 3:**
```
Input:
- Class: KG-1
- Section: Morning
- Roll No: 101
- Student Name: Raj Kumar

Output Filename:
kg_1_morning_101_raj_kumar.jpg
```

---

## Naming Rules

### **Sanitization Applied:**
All components are automatically sanitized:
- **Spaces** → Underscores (`_`)
- **Special characters** → Underscores
- **Multiple underscores** → Single underscore
- **Uppercase** → Lowercase

| Input | Output |
|-------|--------|
| `Grade 10` | `grade_10` |
| `Section-A` | `section_a` |
| `Roll #25` | `roll_25` |
| `John (Doe)` | `john_doe` |

---

## Folder Structure

```
cloudinary/
  └── idcard/
      └── {schoolName}/
          └── {className}/
              └── {sectionName}/
                  ├── grade_10_a_01_john_doe.jpg
                  ├── grade_10_a_02_jane_smith.jpg
                  └── grade_10_a_03_raj_kumar.jpg
```

**Note:** All students from the same class and section are in one folder, with descriptive filenames.

---

## Usage in Code

### **Complete Example:**

```dart
// Navigate to camera screen with all details
final imageUrl = await Navigator.push<String>(
  context,
  MaterialPageRoute(
    builder: (context) => CameraScreen(
      studentId: student.id,           // For Firestore reference
      className: 'Grade 10',            // Used in filename
      sectionName: 'A',                 // Used in filename
      rollNo: '25',                     // Used in filename ⭐
      studentName: 'John Doe',          // Used in filename ⭐
    ),
  ),
);

// Result filename: grade_10_a_25_john_doe.jpg
```

---

## Parameters

### **Required:**
| Parameter | Type | Description | Used In |
|-----------|------|-------------|---------|
| `studentId` | `String` | Firestore document ID | Internal reference |
| `className` | `String` | Student's class | Filename + Folder |
| `sectionName` | `String` | Student's section | Filename + Folder |

### **Optional (but recommended):**
| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `rollNo` | `String?` | `studentId` | Student's roll number |
| `studentName` | `String?` | `'student'` | Student's name |

---

## Default Behavior

If optional parameters are not provided:

```dart
CameraScreen(
  studentId: 'student_abc123',
  className: 'Grade 10',
  sectionName: 'A',
  // rollNo: null,        ← Will use studentId
  // studentName: null,   ← Will use 'student'
)

// Result: grade_10_a_student_abc123_student.jpg
```

**⚠️ Recommendation:** Always provide `rollNo` and `studentName` for better file identification!

---

## Benefits

### ✅ **Self-Descriptive**
You can tell what the photo is just from the filename:
```
grade_10_a_25_john_doe.jpg
   ↓      ↓  ↓     ↓
 Class  Sec Roll  Name
```

### ✅ **Easy Search**
Find photos by any component:
- All Grade 10 photos: `grade_10_*`
- All Section A: `*_a_*`
- Specific roll number: `*_25_*`
- Specific student: `*_john_doe*`

### ✅ **Unique Per Student**
Combination of Class + Section + RollNo + Name ensures uniqueness.

### ✅ **Auto-Overwrite**
Re-uploading the same student automatically replaces old photo.

---

## Complete Integration Example

### **Student Model:**

```dart
class Student {
  final String id;
  final String name;
  final String rollNo;
  final String? photoUrl;
  
  Student({
    required this.id,
    required this.name,
    required this.rollNo,
    this.photoUrl,
  });
}
```

### **Camera Integration:**

```dart
class StudentCard extends StatelessWidget {
  final Student student;
  final String className;
  final String sectionName;

  Future<void> _takePhoto(BuildContext context) async {
    final imageUrl = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => CameraScreen(
          studentId: student.id,
          className: className,
          sectionName: sectionName,
          rollNo: student.rollNo,          // ⭐ Pass roll number
          studentName: student.name,        // ⭐ Pass student name
        ),
      ),
    );
    
    if (imageUrl != null) {
      // Update Firestore with new photo URL
      await FirebaseFirestore.instance
          .collection('students')
          .doc(student.id)
          .update({
            'photoUrl': imageUrl,
            'photoUpdatedAt': FieldValue.serverTimestamp(),
          });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: student.photoUrl != null
              ? NetworkImage(student.photoUrl!)
              : null,
        ),
        title: Text(student.name),
        subtitle: Text('Roll No: ${student.rollNo}'),
        trailing: IconButton(
          icon: Icon(Icons.camera_alt),
          onPressed: () => _takePhoto(context),
        ),
      ),
    );
  }
}
```

---

## URL Examples

### **Cloudinary URL Structure:**

```
https://res.cloudinary.com/dyoydiz81/image/upload/
v1698765432/
idcard/greenwood_high_school/grade_10/a/
grade_10_a_25_john_doe.jpg
```

### **Breakdown:**
```
https://res.cloudinary.com/{cloudName}/image/upload/
v{version}/
{folderPath}/
{filename}
```

---

## Testing

### **Test Different Scenarios:**

```dart
// Test 1: Full details
CameraScreen(
  studentId: 'stu_001',
  className: 'Grade 10',
  sectionName: 'A',
  rollNo: '25',
  studentName: 'John Doe',
)
// Expected: grade_10_a_25_john_doe.jpg

// Test 2: Special characters
CameraScreen(
  studentId: 'stu_002',
  className: 'Class 12-B',
  sectionName: 'Section (C)',
  rollNo: '03',
  studentName: 'Mary O\'Brien',
)
// Expected: class_12_b_section_c_03_mary_o_brien.jpg

// Test 3: Without optional params
CameraScreen(
  studentId: 'stu_003',
  className: 'Grade 9',
  sectionName: 'B',
)
// Expected: grade_9_b_stu_003_student.jpg
```

---

## Cloudinary Dashboard View

In your Cloudinary Media Library:

```
📁 idcard
   📁 greenwood_high_school
      📁 grade_10
         📁 a
            📷 grade_10_a_01_john_doe.jpg
            📷 grade_10_a_02_jane_smith.jpg
            📷 grade_10_a_25_raj_kumar.jpg
         📁 b
            📷 grade_10_b_01_sarah_lee.jpg
            📷 grade_10_b_15_tom_wilson.jpg
```

---

## Migration from Old Format

If you have existing photos with old naming:

### **Old Format:**
```
student_12345_photo.jpg
```

### **New Format:**
```
grade_10_a_25_john_doe.jpg
```

**Action Required:**
- Re-upload photos using the camera screen
- Old photos will be replaced automatically (different filename)
- Or manually rename in Cloudinary dashboard

---

## Summary

| Aspect | Details |
|--------|---------|
| **Format** | `Class_Section_RollNo_StudentName.jpg` |
| **Sanitization** | Automatic (lowercase, underscores) |
| **Uniqueness** | Class + Section + RollNo + Name |
| **Overwrite** | Yes (same filename = replace) |
| **Search-friendly** | Yes (descriptive names) |
| **Required Params** | studentId, className, sectionName |
| **Optional Params** | rollNo, studentName |
| **Recommendation** | Always provide rollNo and studentName |

---

**Remember:** Always pass `rollNo` and `studentName` when using CameraScreen for best results! 📸

