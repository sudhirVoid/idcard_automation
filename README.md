# 📱 ID Card Automation App

A Flutter mobile app for schools to manage student data and capture photos for ID cards, with Firebase backend and Cloudinary image storage.

---

## ✨ Features

### 🔐 Authentication
- **Login Screen** with role-based access (School / Designer)
- Firebase Authentication
- Role verification from Firestore
- Beautiful gradient UI with animations

### 👤 User Profile
- View user details (name, email, role)
- Account information display
- Logout functionality

### 📸 Camera & Image Processing
- Take student photos
- **Auto-crop** images with multiple aspect ratios
- Upload to **Cloudinary**
- Organized folder structure by school name
- Loading indicators and error handling

### 🏫 School Management
- Manage schools, classes, sections
- Student data management
- Excel sheet import (existing feature)

---

## 🚀 Quick Start

### 1. Install Dependencies
```bash
flutter pub get
```

### 2. Configure Firebase
See `FIRESTORE_SETUP.md` for detailed instructions:
- Enable Firestore Database
- Enable Email/Password Authentication
- Create test users
- Set up security rules

### 3. Configure Cloudinary
See `CLOUDINARY_SETUP.md` for detailed instructions:
- Create Cloudinary account
- Get Cloud Name
- Create Upload Preset
- Update `lib/services/cloudinary_service.dart`

### 4. Run the App
```bash
flutter run
```

---

## 📁 Project Structure

```
lib/
├── main.dart                      # App entry point
├── firebase_options.dart          # Firebase configuration
├── screens/
│   ├── login_screen.dart         # ✨ Login with role selection
│   ├── profile_screen.dart       # 👤 User profile & logout
│   ├── camera_screen.dart        # 📸 Camera with Cloudinary upload
│   ├── image_crop_screen.dart    # ✂️ Image cropping
│   ├── schools_screen.dart       # 🏫 Schools list
│   ├── classes_screen.dart       # Classes management
│   ├── sections_screen.dart      # Sections management
│   └── students_screen.dart      # Students management
├── services/
│   └── cloudinary_service.dart   # ☁️ Image upload service
└── models/
    ├── school_model.dart
    ├── class_model.dart
    ├── section_model.dart
    └── student_model.dart
```

---

## 🗄️ Database Structure

### Firestore Collections

#### `users` Collection
```json
{
  "userId": {
    "role": "school" | "designer",
    "name": "School Name",
    "email": "user@example.com"
  }
}
```

#### `schools` Collection (to be created)
```json
{
  "schoolId": {
    "name": "School Name",
    "address": "...",
    "students": []
  }
}
```

### Cloudinary Folder Structure
```
cloudinary/
  └── idcard/
      └── {school_name}/
          └── {class_name}/
              └── {section_name}/
                  └── {student_id}/
                      └── photo.jpg
```

---

## 🔄 User Flow

### Login Flow
```
1. Open App
   ↓
2. Login Screen → Select Role (School/Designer)
   ↓
3. Enter Email & Password
   ↓
4. Firebase Authentication
   ↓
5. Verify Role in Firestore
   ↓
6. If Match → Home Screen
   If Not → Error Message
```

### Photo Upload Flow
```
1. Navigate to Camera Screen
   ↓
2. Take Photo
   ↓
3. Crop Image (Auto-opens)
   ↓
4. Upload to Cloudinary
   ↓
5. Save URL to Firestore
   ↓
6. Return to Previous Screen
```

---

## 🛠️ Technologies Used

- **Flutter** - Cross-platform mobile framework
- **Firebase Core** - Firebase initialization
- **Firebase Auth** - User authentication
- **Cloud Firestore** - NoSQL database
- **Camera** - Device camera access
- **Image Cropper** - Image editing
- **Cloudinary** - Cloud-based image storage
- **Material 3** - Modern UI design

---

## 📦 Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  firebase_core: ^3.1.0
  firebase_auth: ^5.1.0
  cloud_firestore: ^5.0.1
  camera: ^0.11.2
  image_cropper: ^8.0.2
  cloudinary_public: ^0.23.1
  file_picker: ^10.3.3
  excel: ^4.0.0
  path_provider: ^2.1.3
  http: ^1.2.0
```

---

## 🔧 Configuration Files

- `FIRESTORE_SETUP.md` - Firebase & Firestore configuration guide
- `CLOUDINARY_SETUP.md` - Cloudinary setup instructions
- `SETUP_COMPLETE.md` - Complete setup checklist

---

## 🎯 Current Features

- ✅ Login with role verification
- ✅ User profile with logout
- ✅ Camera with image cropping
- ✅ Cloudinary image upload
- ✅ Firebase Authentication
- ✅ Firestore integration
- ✅ Schools management (basic)
- ✅ Excel import support

---

## 🚧 Upcoming Features

- [ ] Complete school/class/student CRUD
- [ ] ID card template design
- [ ] Bulk photo upload
- [ ] ID card PDF generation
- [ ] Export functionality
- [ ] Print integration
- [ ] Analytics dashboard

---

## 📝 License

This project is private and proprietary.

---

## 👨‍💻 Development

### Running the App
```bash
# Development mode
flutter run

# Release mode
flutter run --release

# Build APK
flutter build apk

# Build for iOS
flutter build ios
```

### Testing
```bash
# Run tests
flutter test

# Check for issues
flutter analyze
```

### Cleaning
```bash
# Clean build files
flutter clean

# Reinstall dependencies
flutter pub get
```

---

## 🐛 Troubleshooting

See individual setup guides for specific issues:
- Login issues → `FIRESTORE_SETUP.md`
- Upload issues → `CLOUDINARY_SETUP.md`
- General setup → `SETUP_COMPLETE.md`

---

## 📞 Support

For issues or questions, check the documentation files or contact the development team.

---

**Built with ❤️ using Flutter**
