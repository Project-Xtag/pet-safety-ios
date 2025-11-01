# Pet Safety - iOS App

Native iOS application for the Pet Safety QR tag system.

## Features

- **Passwordless Authentication**: OTP-based email login
- **Pet Management**: Create, edit, and manage pet profiles with photos
- **QR Code Scanning**: Scan QR tags to view pet information and contact owners
- **Missing Pet Alerts**: Report missing pets with location-based notifications
- **Order Management**: View order history and QR tag assignments
- **Community Sightings**: Report and view sightings of missing pets
- **Location Services**: Geolocation for missing pet alerts and sightings

## Architecture

- **Pattern**: MVVM (Model-View-ViewModel)
- **UI Framework**: SwiftUI
- **Networking**: URLSession with async/await
- **Data Persistence**: UserDefaults for auth tokens
- **Location**: CoreLocation
- **Camera**: AVFoundation for QR scanning

## Project Structure

```
PetSafety/
├── App/
│   ├── PetSafetyApp.swift      # App entry point
│   └── ContentView.swift        # Main container view
├── Models/
│   ├── User.swift              # User and auth models
│   ├── Pet.swift               # Pet models
│   ├── Alert.swift             # Missing pet alert models
│   ├── Order.swift             # Order and payment models
│   └── QRTag.swift             # QR tag models
├── ViewModels/
│   ├── AuthViewModel.swift     # Authentication logic
│   ├── PetsViewModel.swift     # Pet management logic
│   ├── AlertsViewModel.swift   # Missing pet alerts logic
│   ├── OrdersViewModel.swift   # Order management logic
│   └── QRScannerViewModel.swift # QR scanning logic
├── Views/
│   ├── Auth/                   # Login and OTP views
│   ├── Pets/                   # Pet list, detail, and form views
│   ├── Alerts/                 # Alert list, create, and detail views
│   ├── Orders/                 # Order list and detail views
│   ├── QRScanner/              # QR scanner view
│   ├── Profile/                # User profile and settings views
│   └── Settings/               # App settings views
├── Services/
│   └── APIService.swift        # Backend API integration
└── Resources/
    └── Colors.xcassets/        # Color assets

```

## Requirements

- iOS 16.0+
- Xcode 16.0+
- Swift 6.0+

## Setup

1. Clone the repository:
   ```bash
   git clone https://github.com/Project-Xtag/pet-safety-ios.git
   cd pet-safety-ios
   ```

2. Open the project in Xcode:
   ```bash
   open PetSafety/PetSafety.xcodeproj
   ```

3. Update the backend URL in `Services/APIService.swift`:
   ```swift
   private let baseURL = "https://your-backend-url.com/api"
   ```

4. Build and run the project in Xcode (⌘R)

## Configuration

### Backend API

Update the `baseURL` in `PetSafety/Services/APIService.swift` to point to your backend server.

### Bundle Identifier

Update the bundle identifier in Xcode:
1. Select the project in the navigator
2. Select the PetSafety target
3. Update the Bundle Identifier under "Signing & Capabilities"

### Permissions

The app requires the following permissions (configured in Info.plist):
- Camera: For QR code scanning
- Photo Library: For uploading pet photos
- Location: For missing pet alerts and sightings

## Building for Production

1. Update the version and build number in the project settings
2. Configure code signing with your Apple Developer account
3. Archive the project (Product > Archive)
4. Upload to App Store Connect

## API Integration

The app communicates with the Pet Safety backend using RESTful APIs. See `APIService.swift` for endpoint details.

All API requests use:
- JWT authentication (Bearer token)
- JSON request/response format
- ISO8601 date formatting

## Contributing

1. Create a feature branch
2. Make your changes
3. Test thoroughly on physical devices
4. Submit a pull request

## License

Copyright © 2024 Pet Safety. All rights reserved.

## Support

For issues or questions:
- Email: support@petsafety.eu
- GitHub Issues: https://github.com/Project-Xtag/pet-safety-ios/issues
