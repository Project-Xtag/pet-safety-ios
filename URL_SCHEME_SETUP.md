# URL Scheme Configuration for Pet Safety iOS App

This document explains how to configure the URL scheme and Universal Links to enable deep linking for QR code tag activation.

## 1. Custom URL Scheme (senra://)

### Configure in Xcode:

1. Open the project in Xcode
2. Select the **PetSafety** target
3. Go to **Info** tab
4. Expand **URL Types**
5. Click **+** to add a new URL Type
6. Configure:
   - **Identifier**: `com.senra.petsafety`
   - **URL Schemes**: `petsafety`
   - **Role**: Editor

### Supported URLs:
- `senra://tag/PS-XXXXXXXX` - Opens tag activation for the specified code

### Test:
```bash
# On Mac with simulator running:
xcrun simctl openurl booted "senra://tag/PS-TEST1234"
```

---

## 2. Universal Links (https://senra.pet/)

Universal Links allow the app to open when users tap links on websites or in messages.

### Step 1: Configure Associated Domains in Xcode

1. Select the **PetSafety** target
2. Go to **Signing & Capabilities** tab
3. Click **+ Capability**
4. Add **Associated Domains**
5. Add these domains:
   - `applinks:senra.pet`
   - `applinks:www.senra.pet`

### Step 2: Create Apple App Site Association (AASA) File

The server (senra.pet) needs to host this file at:
`https://senra.pet/.well-known/apple-app-site-association`

```json
{
  "applinks": {
    "apps": [],
    "details": [
      {
        "appID": "TEAM_ID.com.senra.petsafety",
        "paths": [
          "/qr/*"
        ]
      }
    ]
  }
}
```

**Replace `TEAM_ID` with your Apple Developer Team ID.**

### Step 3: Deploy AASA File

Add this to your backend/nginx configuration to serve the AASA file:

```nginx
# In nginx.conf or site config
location /.well-known/apple-app-site-association {
    default_type application/json;
    add_header Content-Type application/json;
}
```

### Supported URLs:
- `https://senra.pet/qr/PS-XXXXXXXX` - Opens tag activation

---

## 3. How It Works

### Flow:
1. User scans physical QR code with camera (contains URL: `https://senra.pet/qr/PS-XXXXXXXX`)
2. iOS detects the URL and checks if any app handles it via Universal Links
3. If Pet Safety app is installed → App opens with TagActivationView
4. If app not installed → Safari opens the web version

### Code Files:
- `Services/DeepLinkService.swift` - Parses URLs and extracts tag codes
- `Views/Tags/TagActivationView.swift` - UI for activating tags
- `App/ContentView.swift` - Handles `.onOpenURL` and presents TagActivationView

---

## 4. Testing

### Test Custom Scheme:
```bash
# Simulator
xcrun simctl openurl booted "senra://tag/PS-TEST1234"

# Or use Safari on device/simulator:
# Type: senra://tag/PS-TEST1234
```

### Test Universal Links:
1. Send yourself an iMessage with: `https://senra.pet/qr/PS-TEST1234`
2. Tap the link on the device with the app installed
3. Should open the app directly

### Debug:
Add this to AppDelegate or check console for:
```swift
print("🔗 Received URL: \(url.absoluteString)")
```

---

## 5. Troubleshooting

### Universal Links not working:
1. Check AASA file is valid: https://branch.io/resources/aasa-validator/
2. Ensure AASA is served with correct Content-Type: `application/json`
3. Make sure the app was installed after AASA was deployed
4. Try reinstalling the app

### Custom scheme not working:
1. Verify URL scheme is added in Xcode Info tab
2. Check the `.onOpenURL` modifier is in the view hierarchy
3. Ensure the URL format is correct: `senra://tag/CODE`

---

## 6. QR Code Format

### Physical Tags Should Encode:
```
https://senra.pet/qr/PS-XXXXXXXX
```

This format:
- Works on any phone (opens web browser if app not installed)
- Opens the iOS app directly if installed (via Universal Links)
- Is human-readable if needed

### Alternative (App-Only):
```
senra://tag/PS-XXXXXXXX
```

This only works if the app is installed - not recommended for physical tags.
