# Cloudinary Setup Guide

## Overview

This app uses Cloudinary to store student photos in organized folders by school name. Images are automatically cropped by users before uploading.

## Setup Steps

### 1. Create Cloudinary Account

1. Go to: https://cloudinary.com/users/register/free
2. Sign up for a free account
3. Verify your email

### 2. Get Your Credentials

After logging in to your Cloudinary Dashboard:

1. **Cloud Name**: Found in the dashboard header (e.g., `dxxx123abc`)
2. **Upload Preset**: You need to create one

### 3. Create Upload Preset

1. Go to **Settings** → **Upload**
2. Scroll down to **Upload presets**
3. Click **Add upload preset**
4. Configure:
   - **Preset name**: `id_card_uploads` (or any name you prefer)
   - **Signing mode**: Select **"Unsigned"** (for mobile app uploads)
   - **Folder**: Leave empty (app will set this dynamically)
   - **Access mode**: **"Public"**
5. Click **Save**

### 4. Update App Configuration

Open `lib/services/cloudinary_service.dart` and update:

```dart
class CloudinaryService {
  static const String cloudName = 'YOUR_CLOUD_NAME'; // Replace with your cloud name
  static const String uploadPreset = 'YOUR_UPLOAD_PRESET'; // Replace with your preset name
  
  // ... rest of the code
}
```

**Example:**
```dart
class CloudinaryService {
  static const String cloudName = 'dxxx123abc';
  static const String uploadPreset = 'id_card_uploads';
  
  // ... rest of the code
}
```

## How It Works

### Folder Structure

Images are automatically organized in Cloudinary:

```
cloudinary/
  └── idcard/
      └── {school_name}/
          └── {class_name}/
              └── {section_name}/
                  └── {student_id}/
                      └── image_1234567890.jpg
```

**Example:**
```
cloudinary/
  └── idcard/
      └── greenwood_high_school/
          └── grade_10/
              └── section_a/
                  └── student_12345/
                      └── image_1698765432.jpg
```

### Upload Flow

1. User takes a photo with camera
2. Image cropper opens automatically
3. User crops the image
4. App uploads cropped image to Cloudinary
5. Image is stored under: `idcard/{school_name}/{class_name}/{section_name}/{student_id}/`
6. App receives the secure URL

### School Name Source

The school name is fetched from Firestore:
- Collection: `users`
- Document: Current user's UID
- Field: `name` (should contain the school name)

**Make sure to add `name` field to user documents in Firestore:**

```json
{
  "role": "school",
  "email": "school@example.com",
  "name": "Greenwood High School"  ← This is used for folder name
}
```

## Android Configuration

For Android, add to `android/app/src/main/AndroidManifest.xml` (inside `<application>` tag):

```xml
<activity
    android:name="com.yalantis.ucrop.UCropActivity"
    android:screenOrientation="portrait"
    android:theme="@style/Theme.AppCompat.Light.NoActionBar"/>
```

## iOS Configuration

For iOS, add to `ios/Runner/Info.plist`:

```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>This app requires access to the photo library to crop images.</string>
<key>NSCameraUsageDescription</key>
<string>This app requires camera access to take photos.</string>
```

## Usage in Code

### Take Picture with Camera

```dart
// Navigate to camera screen with student ID
final imageUrl = await Navigator.push<String>(
  context,
  MaterialPageRoute(
    builder: (context) => CameraScreen(
      studentId: 'student_12345', // Pass actual student ID
    ),
  ),
);

if (imageUrl != null) {
  print('Image uploaded: $imageUrl');
  // Save imageUrl to Firestore with student data
}
```

### Camera Screen Features

- ✅ Take photo
- ✅ Auto-open crop editor
- ✅ Crop with multiple aspect ratios
- ✅ Upload to Cloudinary
- ✅ Save in school-specific folder
- ✅ Return secure URL

## Testing

1. **Update Cloudinary credentials** in `cloudinary_service.dart`
2. **Add `name` field** to your user in Firestore
3. **Run the app**
4. **Navigate to camera screen**
5. **Take a picture**
6. **Crop the image**
7. **Wait for upload**
8. **Check Cloudinary dashboard** to see the uploaded image

## Free Tier Limits

Cloudinary free tier includes:
- 25 GB storage
- 25 GB bandwidth per month
- Unlimited transformations

This should be sufficient for testing and small-scale use.

## Security Considerations

### Current Setup (Development)
- Using **unsigned uploads** with upload preset
- Anyone with the preset can upload

### Production Recommendations
1. **Server-side signing**: Generate signed upload URLs from your backend
2. **Add authentication**: Verify user before allowing upload
3. **Rate limiting**: Prevent abuse
4. **File size limits**: Restrict upload size

## Troubleshooting

### Upload fails with "Missing required parameter"
- Check if `cloudName` and `uploadPreset` are correctly set
- Verify upload preset is set to "Unsigned" mode

### Folder not created
- Check if user's `name` field exists in Firestore
- Verify the user is logged in

### Crop screen doesn't open
- Check Android/iOS permissions
- Verify `image_cropper` package is properly installed

## Support

- Cloudinary Docs: https://cloudinary.com/documentation
- Image Cropper Plugin: https://pub.dev/packages/image_cropper

