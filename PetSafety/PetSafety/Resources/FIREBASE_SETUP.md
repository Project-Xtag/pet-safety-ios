# Firebase Setup for Pet Safety iOS

## Required: GoogleService-Info.plist

To enable push notifications via Firebase Cloud Messaging (FCM), you need to:

1. **Create a Firebase project** (if not already done)
   - Go to [Firebase Console](https://console.firebase.google.com)
   - Create a new project or use existing "Pet Safety EU" project

2. **Add iOS app to Firebase**
   - Click "Add app" and select iOS
   - Enter bundle ID: `com.petsafety.app` (or your actual bundle ID)
   - Download the `GoogleService-Info.plist` file

3. **Add the file to Xcode**
   - Drag `GoogleService-Info.plist` to this Resources folder
   - Make sure "Copy items if needed" is checked
   - Add to target: PetSafety

4. **Enable Push Notifications in Firebase**
   - In Firebase Console, go to Project Settings > Cloud Messaging
   - Upload your APNs authentication key (.p8 file from Apple Developer Portal)
   - Or upload APNs certificates

## APNs Setup (Apple Developer Portal)

1. Go to [Apple Developer Portal](https://developer.apple.com)
2. Navigate to Certificates, Identifiers & Profiles
3. Create an APNs Key (recommended) or Certificate
4. Download the .p8 key file
5. Upload to Firebase Console

## Backend Environment Variables

The backend needs these Firebase credentials (already set up in env.ts):

```
FIREBASE_PROJECT_ID=your-project-id
FIREBASE_CLIENT_EMAIL=firebase-adminsdk-xxx@your-project.iam.gserviceaccount.com
FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n"
```

Get these from Firebase Console > Project Settings > Service Accounts > Generate new private key.

## Testing Push Notifications

1. Build and run on a real device (simulator doesn't support push)
2. Grant notification permissions when prompted
3. Check console for "FCM token received: ..."
4. Use Firebase Console > Cloud Messaging to send test notification

## Files in this directory

- `GoogleService-Info.plist` - Firebase configuration (YOU NEED TO ADD THIS)
- `FIREBASE_SETUP.md` - This file
