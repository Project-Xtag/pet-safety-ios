# Pet Safety iOS App - Setup Guide

## Quick Start

Since this is a SwiftUI project with all source files ready, you have two options to open it in Xcode:

### Option 1: Create Xcode Project (Recommended)

1. Open Xcode
2. File → New → Project
3. Choose "iOS" → "App"
4. Configure the project:
   - Product Name: `PetSafety`
   - Team: Select your team
   - Organization Identifier: `com.petsafety` (or your preferred)
   - Interface: `SwiftUI`
   - Language: `Swift`
   - Storage: None
5. Save it in the `pet-safety-ios` folder (replace the empty PetSafety folder)
6. The source files are already organized in the correct structure

### Option 2: Manual Import

1. Create a new Xcode project as described above
2. Delete the default ContentView.swift and App file
3. Drag and drop all folders from `PetSafety/PetSafety/` into your Xcode project

## Configuration Steps

### 1. Update Backend URL

Edit `PetSafety/Services/APIService.swift`:

```swift
private let baseURL = "https://your-actual-backend.com/api"  // Update this line
```

Replace with your actual backend URL (from the pet-safety-eu backend).

### 2. Configure Signing

1. In Xcode, select the project in the navigator
2. Select the "PetSafety" target
3. Go to "Signing & Capabilities"
4. Select your team
5. Xcode will automatically manage provisioning

### 3. Add Required Capabilities

The app needs these capabilities (already configured in Info.plist):
- ✅ Camera access (for QR scanning)
- ✅ Photo Library access (for pet photos)
- ✅ Location services (for missing pet alerts)

### 4. Test on Simulator or Device

1. Select a simulator or connected device
2. Press ⌘R to build and run
3. Test the authentication flow first

## Project Structure Overview

```
PetSafety/
├── App/                    # App entry point and main container
├── Models/                 # Data models (User, Pet, Alert, Order, QRTag)
├── ViewModels/            # Business logic (MVVM pattern)
├── Views/                 # SwiftUI views organized by feature
│   ├── Auth/             # Login and OTP verification
│   ├── Pets/             # Pet management (list, detail, form)
│   ├── Alerts/           # Missing pet alerts with maps
│   ├── Orders/           # Order history
│   ├── QRScanner/        # QR code scanner
│   └── Profile/          # User profile and settings
├── Services/             # API service layer
└── Resources/            # Assets and colors
```

## Key Features Implemented

✅ **Authentication**
- OTP email login
- JWT token management
- Auto-login on app restart

✅ **Pet Management**
- Create, edit, delete pets
- Upload pet photos
- View pet details

✅ **QR Code Scanning**
- Camera-based QR scanner
- View scanned pet information
- Contact owner directly

✅ **Missing Pet Alerts**
- Create alerts with location
- View alerts on map
- Report sightings
- Automatic vet/shelter notifications

✅ **Orders**
- View order history
- Track order status
- See QR tag assignments

✅ **Profile Management**
- Edit user information
- Update address
- App settings

## Testing Checklist

Before deploying, test these flows:

1. **Authentication**
   - [ ] Request OTP code
   - [ ] Verify OTP
   - [ ] Auto-login on restart
   - [ ] Logout

2. **Pet Management**
   - [ ] Add new pet
   - [ ] Upload photo
   - [ ] Edit pet details
   - [ ] Delete pet

3. **QR Scanner**
   - [ ] Grant camera permission
   - [ ] Scan QR code
   - [ ] View pet information
   - [ ] Contact owner

4. **Missing Alerts**
   - [ ] Create alert with location
   - [ ] View alert on map
   - [ ] Report sighting
   - [ ] Mark as found

5. **Orders**
   - [ ] View order history
   - [ ] See order details

6. **Profile**
   - [ ] Edit profile information
   - [ ] Update settings

## Common Issues

### Camera Not Working
- Check Info.plist has `NSCameraUsageDescription`
- Grant camera permission in Settings
- Test on physical device (simulator has limited camera support)

### Location Not Working
- Check Info.plist has location usage descriptions
- Grant location permission
- Test on physical device for better results

### API Errors
- Verify backend URL is correct
- Check network connectivity
- Inspect logs in Xcode console
- Verify backend is running and accessible

### Build Errors
- Clean build folder (⇧⌘K)
- Update signing settings
- Ensure Xcode 16+ and iOS 16+ deployment target

## Next Steps

1. **Connect to Backend**: Update the API base URL
2. **Test Authentication**: Ensure OTP emails are sent
3. **Upload to TestFlight**: For beta testing
4. **Submit to App Store**: Follow Apple's review guidelines

## Development Tips

- Use SwiftUI Previews for fast iteration (⌥⌘P)
- Test on multiple screen sizes (iPhone SE, iPhone 15 Pro Max, iPad)
- Test in both light and dark mode
- Use Instruments for performance profiling
- Enable SwiftLint for code quality (optional)

## Support

For technical issues or questions:
- GitHub Issues: https://github.com/Project-Xtag/pet-safety-ios/issues
- Email: support@petsafety.eu
