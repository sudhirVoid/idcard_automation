# Firestore Database Setup Guide

## Database Structure

### Users Collection

The `users` collection stores user profiles with their assigned roles.

```
users/
  ├── {userId}/
  │   ├── role: "school" | "designer"
  │   ├── email: "user@example.com" (optional)
  │   └── name: "User Name" (optional)
```

## Setting Up Users in Firestore

### Method 1: Manual Setup via Firebase Console

1. **Go to Firebase Console:**
   - Visit: https://console.firebase.google.com/project/idcard-30721
   - Navigate to **Firestore Database**

2. **Create the `users` Collection:**
   - Click **Start collection**
   - Collection ID: `users`

3. **Add User Documents:**
   - Document ID: Use the **Firebase Auth UID** of the user
   - Add fields:
     - `role` (string): Either `school` or `designer`
     - `email` (string, optional): User's email
     - `name` (string, optional): User's display name

### Method 2: Using Firebase Console Script (Bulk Import)

You can also import users via JSON:

```json
{
  "users": {
    "user_id_123abc": {
      "role": "school",
      "email": "school@example.com",
      "name": "School Admin"
    },
    "user_id_456def": {
      "role": "designer",
      "email": "designer@example.com",
      "name": "Designer User"
    }
  }
}
```

## How to Get User ID (UID)

After creating a user in **Firebase Authentication**:
1. Go to **Authentication** → **Users**
2. Find the user in the list
3. Copy their **User UID**
4. Use this UID as the document ID in the `users` collection

## Example: Creating a Test User

### Step 1: Create Authentication User
1. Firebase Console → **Authentication** → **Users**
2. Click **Add user**
3. Email: `school@test.com`
4. Password: `test123456`
5. Click **Add user**
6. Copy the generated **User UID** (e.g., `xY7dK3mPqR...`)

### Step 2: Create Firestore Document
1. Firebase Console → **Firestore Database**
2. Collection: `users`
3. Document ID: Paste the **User UID** from Step 1
4. Add field:
   - Field name: `role`
   - Field type: `string`
   - Value: `school`
5. Click **Save**

### Step 3: Test Login
1. Run the app
2. Select **School** role
3. Enter email: `school@test.com`
4. Enter password: `test123456`
5. Click **Login**

## Security Rules (Important!)

Make sure to set up proper Firestore Security Rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can only read their own user document
    match /users/{userId} {
      allow read: if request.auth != null && request.auth.uid == userId;
      allow write: if false; // Only admins can write via Firebase Console
    }
    
    // Other collections (schools, students, etc.)
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

## Login Flow

1. User selects their role (School or Designer)
2. User enters email and password
3. App authenticates with Firebase Auth
4. App fetches user document from Firestore using `userId`
5. App compares the selected role with the stored role
6. If roles match → Login successful ✅
7. If roles don't match → Show error message ❌

## Error Messages

- **"User profile not found"**: User exists in Auth but not in Firestore
- **"Access denied. You are registered as a {role} user"**: Role mismatch
- **"Invalid credentials"**: Wrong email or password

## Next Steps

1. Enable Email/Password authentication in Firebase Console
2. Create test users in Firebase Authentication
3. Add corresponding user documents in Firestore with roles
4. Test the login flow with different roles

