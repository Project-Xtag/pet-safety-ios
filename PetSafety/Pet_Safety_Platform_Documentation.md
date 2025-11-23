# Pet Safety Platform - Complete Documentation

**Date:** November 23, 2025
**Version:** 1.0
**Platform:** Web App (React) + iOS App (SwiftUI)

---

## Table of Contents

1. [Executive Summary](#executive-summary)
2. [Web App Features](#web-app-features)
3. [iOS App Features](#ios-app-features)
4. [User Journeys & Flowchart](#user-journeys--flowchart)
5. [Implementation Todo List](#implementation-todo-list)
6. [Technical Architecture](#technical-architecture)

---

## Executive Summary

The Pet Safety Platform is a comprehensive solution to help pet owners reunite with their lost pets through QR code technology, location sharing, and community alerts.

### Core Value Proposition
- **Instant Notification**: Pet owners are notified immediately when someone scans their pet's QR tag
- **Location Sharing**: Finders can share their exact GPS location with the owner
- **Privacy Control**: Owners control what contact information is publicly visible
- **Community Alerts**: Missing/Found pet alerts visible to nearby users
- **Multi-Platform**: Works on any device (web) with enhanced features on iOS

### Target Users
- **Pet Owners**: Register pets, create QR tags, manage profiles, report missing pets
- **Finders**: Scan QR codes, share location, view pet information, contact owners
- **Community**: Browse nearby missing/found pet alerts, help reunite pets

---

## Web App Features

### Authentication & User Management
- ✅ **Email/Password Registration & Login**
  - Secure JWT-based authentication
  - Email verification flow
  - Password reset functionality

- ✅ **User Profile Management**
  - Name, email, phone number
  - Address (for location-based features)
  - Profile photo upload

- ✅ **Privacy Settings**
  - Toggle phone number public visibility
  - Toggle email public visibility
  - Default: Both visible (opt-out model)

### Pet Management
- ✅ **Pet Registration**
  - Add multiple pets per account
  - Pet details: name, species, breed, color, age, weight
  - Photo upload with AWS S3 storage
  - Medical information and special notes

- ✅ **Pet Profile Editing**
  - Update all pet information
  - Change profile photo
  - Mark as lost/found

- ✅ **Pet Deletion**
  - Soft delete to preserve alert history
  - Confirmation dialog

### QR Tag System
- ✅ **QR Tag Generation**
  - Automatic QR code generation when pet registered
  - Unique alphanumeric code (12 characters)
  - Downloadable QR code image

- ✅ **QR Tag Activation**
  - Link physical tag to pet profile
  - One-time activation process
  - Validation of tag authenticity

- ✅ **Public Pet Profile** (No Authentication Required)
  - View pet information when QR scanned
  - Pet photo, name, description
  - Owner name (always visible)
  - Owner phone number (if public)
  - Owner email (if public)
  - Automatic owner notification on scan
  - "Share Location" button for finders
  - Call/Email buttons (if contact info public)

### Location Sharing
- ✅ **Real-time Location Capture**
  - Browser geolocation API
  - Capture current GPS coordinates
  - Reverse geocoding to address

- ✅ **Location Sharing Flow**
  1. Finder scans QR code → Public profile loads
  2. Finder clicks "Share Location" button
  3. Browser requests location permission
  4. Current location captured and sent to backend
  5. Owner notified via SMS + Email with map link

- ✅ **Owner Notifications**
  - SMS via AWS SNS/Pinpoint
  - Email via AWS SES
  - Includes finder's location on map
  - Timestamp of sighting

### Subscription & Payments
- ✅ **Stripe Integration**
  - Monthly subscription ($4.99/month)
  - Annual subscription ($49.99/year - save 17%)
  - Free trial period

- ✅ **Subscription Management**
  - View current plan
  - Upgrade/downgrade
  - Cancel subscription
  - Payment method management
  - Invoice history

- ✅ **Feature Gating**
  - Limit free users to 1 pet
  - Unlimited pets for premium subscribers

### Settings & Configuration
- ✅ **Privacy Settings Card**
  - Show phone publicly toggle
  - Show email publicly toggle
  - Real-time updates
  - Visual feedback on save

- ✅ **Account Settings**
  - Change password
  - Update email (with verification)
  - Delete account

### UI/UX Features
- ✅ **Responsive Design**
  - Mobile-first approach
  - Works on all screen sizes
  - Touch-friendly controls

- ✅ **Shadcn/ui Components**
  - Consistent design system
  - Accessible components
  - Beautiful animations

- ✅ **Toast Notifications**
  - Success/error feedback
  - Non-blocking messages
  - Auto-dismiss

---

## iOS App Features

### Authentication & User Management
- ✅ **Email/Password Authentication**
  - Firebase Authentication integration
  - Automatic token refresh
  - Secure keychain storage

- ✅ **User Profile View**
  - Display user information
  - View subscription status

- ⚠️ **Privacy Settings** (TODO)
  - Toggle contact visibility preferences
  - Match web app functionality

### Pet Management
- ✅ **My Pets List**
  - Grid view of all pets
  - Pet photos and names
  - Status indicators (normal/lost/found)

- ✅ **Pet Detail View**
  - Full pet information display
  - Medical notes
  - QR code display
  - Edit/Delete actions

- ✅ **Add/Edit Pet**
  - Complete pet information form
  - Photo picker with camera/library
  - Breed selection
  - Validation

- ✅ **Mark as Lost/Found**
  - Quick action from pet detail
  - Location capture
  - Additional notes
  - Alert creation integration

### QR Code Scanner
- ✅ **Camera-based QR Scanner**
  - AVFoundation camera integration
  - Real-time QR detection
  - Visual scanning indicator
  - Permission handling

- ✅ **Scanned Pet Profile View**
  - Pet information display
  - Automatic owner notification
  - Share location button
  - Contact owner buttons (call/email if public)

- ✅ **Location Sharing**
  - CoreLocation integration
  - GPS coordinate capture
  - "Share Location" modal
  - SMS + Email notification to owner
  - Success confirmation

- ✅ **Quick Actions**
  - "Mark as Found" button
  - Share pet profile
  - Report additional information

### Alerts System
- ✅ **Nearby Alerts View** (NEW)
  - Tab-based interface (Missing/Found)
  - 10km radius from user location
  - Real-time location updates
  - Pull-to-refresh

- ✅ **Missing Pets Tab**
  - List View:
    - Pet photo
    - Pet name
    - "Missing since" date
    - Last seen location
    - Status badge
  - Map View:
    - Pet photos as map markers
    - Red theme for missing
    - Tappable markers
    - Info cards showing duration missing
    - Centered on first alert

- ✅ **Found Pets Tab**
  - List View:
    - Pet photo
    - Pet name
    - "Found on" date
    - Location
    - Green status badge
  - Map View:
    - Pet photos as map markers
    - Green theme for found
    - Tappable markers
    - Info cards with reunited status

- ✅ **Alert Detail View**
  - Full pet information
  - Timeline of sightings
  - Contact options
  - Map with all sighting locations

- ⚠️ **Create Alert** (Partial)
  - Integrated with "Mark as Lost"
  - Location capture
  - Additional info field
  - Photo attachment needed

### Subscription Management
- ✅ **View Subscription Status**
  - Current plan display
  - Expiration date
  - Feature access indicator

- ⚠️ **In-App Purchase** (TODO)
  - StoreKit 2 integration
  - Purchase flow
  - Restore purchases
  - Receipt validation

### Navigation & UI
- ✅ **Tab-based Navigation**
  - My Pets
  - Scan QR
  - Alerts
  - Profile

- ✅ **SwiftUI Modern Design**
  - Native iOS components
  - Smooth animations
  - Dark mode support
  - Accessibility features

- ✅ **Loading States**
  - Progress indicators
  - Skeleton screens
  - Error states
  - Empty states

### Location Services
- ✅ **LocationManager**
  - CoreLocation wrapper
  - Permission handling
  - Real-time updates
  - Background location (for alerts)

- ✅ **Map Integration**
  - MapKit integration
  - Custom annotations
  - User location tracking
  - Region focusing

---

## User Journeys & Flowchart

### Journey 1: Pet Owner - Registration to Alert

```
┌─────────────────────────────────────────────────────────────────────┐
│                        PET OWNER JOURNEY                            │
└─────────────────────────────────────────────────────────────────────┘

[User Opens App/Website]
         │
         ↓
[Registration / Login]
    - Email & Password
    - Email Verification
    - Profile Setup (Name, Phone, Address)
         │
         ↓
[Set Privacy Settings] ← NEW FEATURE
    - Toggle "Show Phone Publicly"
    - Toggle "Show Email Publicly"
    - Default: Both ON (opt-out)
         │
         ↓
[Add Pet Profile]
    - Upload Photo
    - Enter Details (Name, Breed, Age, Color, Weight)
    - Add Medical Info & Special Notes
         │
         ↓
[QR Tag Generated Automatically]
    - Unique 12-char code
    - Downloadable QR image
    - Can print or order physical tag
         │
         ↓
[Receive Physical QR Tag] (if ordered)
    - Attach to pet collar
         │
         ↓
┌─────────── PET GOES MISSING ───────────┐
│                                         │
│   [Owner Marks Pet as Lost]            │
│       - Opens app/website              │
│       - Goes to pet profile            │
│       - Clicks "Mark as Lost"          │
│       - Enters last seen location      │
│       - Adds additional info           │
│            │                            │
│            ↓                            │
│   [Alert Created Automatically]        │
│       - Status: ACTIVE                 │
│       - Visible to nearby users        │
│       - Radius: 10km from last seen    │
│            │                            │
│            ↓                            │
│   [Owner Receives Notifications]       │
│       - When QR tag scanned            │
│       - When location shared           │
│       - When sighting reported         │
│       - SMS + Email + In-app           │
└─────────────────────────────────────────┘
```

### Journey 2: Finder - Discovery to Notification

```
┌─────────────────────────────────────────────────────────────────────┐
│                        FINDER JOURNEY                               │
└─────────────────────────────────────────────────────────────────────┘

[Person Finds Lost Pet]
         │
         ↓
[Scans QR Tag on Collar]
    - Opens camera (any device)
    - Points at QR code
    - Automatic detection
         │
         ↓
[QR Opens Public Pet Profile] ← NO LOGIN REQUIRED
    Web: https://tagme-now.com/pet/ABC123XYZ
    iOS: Opens in-app if installed, else browser
         │
         ↓
┌────────────────────────────────────────────────────┐
│ PUBLIC PET PROFILE DISPLAYS:                       │
│  • Pet Photo                                       │
│  • Pet Name: "Hello! I'm Max"                      │
│  • Thank you message                               │
│  • ✓ "Owner has been notified" badge              │
│                                                    │
│ AUTOMATIC NOTIFICATION SENT:                       │
│  → SMS to owner: "Max's tag was scanned!"         │
│  → Email to owner with timestamp & basic info      │
│                                                    │
│ FINDER SEES CONTACT INFO (if public):             │
│  • Owner Name: Always visible                      │
│  • Owner Phone: If show_phone_publicly = true      │
│  • Owner Email: If show_email_publicly = true      │
│                                                    │
│ FINDER OPTIONS:                                    │
│  [Share Location Button]                          │
│  [Call Button] (if phone public)                  │
│  [Email Button] (if email public)                 │
└────────────────────────────────────────────────────┘
         │
         ↓
[Finder Clicks "Share Location"] ← NEW FEATURE
         │
         ↓
[Browser/App Requests GPS Permission]
    - "Allow location access"
    - One-time or while using
         │
         ↓
[Current Location Captured]
    - Latitude & Longitude
    - Reverse geocoded to address
    - Timestamp recorded
         │
         ↓
[Location Sent to Backend]
    POST /qr-tags/share-location
    {
      qrCode: "ABC123XYZ",
      location: { lat: 51.5074, lng: -0.1278 },
      address: "123 Main St, London"
    }
         │
         ↓
[Owner Notified AGAIN]
    📧 Email: "Max was spotted at [address]!"
           + Link to Google Maps
           + Timestamp

    📱 SMS: "Max spotted at [address] - View location: [map link]"
         │
         ↓
[Success Message to Finder]
    "Location shared successfully!
     Max's owner has been notified via SMS and email."
```

### Journey 3: Pet Found & Reunited

```
┌─────────────────────────────────────────────────────────────────────┐
│                    PET FOUND & REUNITED                             │
└─────────────────────────────────────────────────────────────────────┘

[Owner Sees Notification]
    - SMS: "Max was spotted at..."
    - Email with map link
    - In-app notification
         │
         ↓
[Owner Views Location on Map]
    - Opens Google Maps link
    - Sees exact GPS coordinates
    - Plans retrieval route
         │
         ↓
[Owner Goes to Location]
    - Finds pet
    - Reunites with finder
         │
         ↓
[Owner Marks Pet as Found]
    Web or iOS app:
    - Goes to pet profile
    - Clicks "Mark as Found"
    - Enters found date/location
    - Adds notes (optional)
         │
         ↓
[Alert Status Updated]
    - Status: ACTIVE → RESOLVED
    - Moved from "Missing" to "Found" tab
    - Still visible for 7 days (success story)
    - Visible in 10km radius
         │
         ↓
[Community Notified]
    - Users who viewed alert get update
    - Alert appears in "Found" tab with green badge
    - Shows reunion date
         │
         ↓
[Owner Can Share Success Story] (Future feature)
    - Optional photo of reunion
    - Thank you message to community
    - Helps build trust in platform
```

### Additional Flow: Community Alerts

```
┌─────────────────────────────────────────────────────────────────────┐
│                    COMMUNITY ALERTS VIEW                            │
└─────────────────────────────────────────────────────────────────────┘

[User Opens Alerts Tab]
    iOS: Tab navigation
    Web: To be implemented
         │
         ↓
[App Requests Location Permission]
    - Background location (iOS)
    - Current location only (Web)
         │
         ↓
[Fetch Nearby Alerts]
    GET /alerts/nearby?lat=51.5074&lng=-0.1278&radius=10
    - Within 10km radius
    - User's registered address OR current location
         │
         ↓
[Separate by Status]
    • ACTIVE alerts → "Missing" tab (red theme)
    • RESOLVED alerts → "Found" tab (green theme)
         │
         ↓
┌────────────────────────────────────────────────────┐
│ MISSING TAB                                        │
│                                                    │
│  [List View ▼] [Map View]                         │
│                                                    │
│  LIST VIEW:                                        │
│  ┌──────────────────────────────────┐            │
│  │ [Photo] Max                      │            │
│  │         Missing since 2 days ago │            │
│  │         📍 Central Park          │  →         │
│  └──────────────────────────────────┘            │
│                                                    │
│  MAP VIEW:                                         │
│  • Pet photos as red circle markers               │
│  • Tap marker → info card appears                 │
│  • Card shows: name, duration missing, location   │
│  • Tap card → full alert detail view              │
└────────────────────────────────────────────────────┘
         │
         ↓
┌────────────────────────────────────────────────────┐
│ FOUND TAB                                          │
│                                                    │
│  [List View ▼] [Map View]                         │
│                                                    │
│  LIST VIEW:                                        │
│  ┌──────────────────────────────────┐            │
│  │ [Photo] Bella                    │            │
│  │         ✓ Found & Reunited       │            │
│  │         Found on Jan 15          │  →         │
│  │         📍 Hyde Park             │            │
│  └──────────────────────────────────┘            │
│                                                    │
│  MAP VIEW:                                         │
│  • Pet photos as green circle markers             │
│  • Success stories visible for 7 days             │
│  • Builds trust in platform effectiveness         │
└────────────────────────────────────────────────────┘
```

---

## Implementation Todo List

### HIGH PRIORITY

#### 1. User Registered Address
**Status:** 🔴 Not Started
**Platforms:** Web + iOS + Backend

**Requirements:**
- Add address fields to user profile (street, city, state/province, postal code, country)
- Display in Settings/Profile pages
- Use for default location in alerts (instead of hardcoded London coordinates)
- Validation for address format
- Geocoding to lat/lng for radius queries

**Files to Modify:**
- Backend: `User` model, database migration
- Web: `src/pages/Settings.tsx`, user API
- iOS: `ProfileView.swift`, `User.swift`, API service

---

#### 2. Web App - Alerts Page
**Status:** 🔴 Not Started
**Platforms:** Web

**Requirements:**
- Create Alerts page matching iOS implementation
- Missing/Found tabs with segmented control
- List view: pet photo, name, date, location
- Map view: pet photo markers, tappable info cards
- Fetch from `/alerts/nearby` endpoint
- 10km radius from user's registered address
- Responsive design for mobile/desktop

**New Files:**
- `src/pages/Alerts.tsx`
- `src/components/alerts/MissingAlertsList.tsx`
- `src/components/alerts/FoundAlertsList.tsx`
- `src/components/alerts/AlertsMap.tsx`
- `src/components/alerts/AlertCard.tsx`

**Dependencies:**
- Google Maps JavaScript API or Mapbox
- Geolocation API for current location
- User registered address implementation (#1)

---

#### 3. iOS - Complete Mark as Found
**Status:** 🟡 Partial (UI exists, backend incomplete)
**Platforms:** iOS + Backend

**Current State:**
- `QuickMarkFoundView.swift` exists but catch block unreachable
- Backend endpoint missing or incomplete

**Requirements:**
- Fix error handling in QuickMarkFoundView
- Implement backend `PATCH /alerts/:id/status` if missing
- Update alert status to "resolved"
- Move alert from missing to found arrays
- Show success confirmation
- Refresh alerts list

**Files to Modify:**
- iOS: `QuickMarkFoundView.swift`, `AlertsViewModel.swift`
- Backend: Alert controller, ensure status update endpoint exists

---

#### 4. iOS - Privacy Settings View
**Status:** 🔴 Not Started
**Platforms:** iOS

**Requirements:**
- Add Privacy Settings section in ProfileView
- Toggles for "Show Phone Publicly" and "Show Email Publicly"
- Match web app functionality
- Use `updateContactPreferences` API method (already implemented)
- Real-time state updates
- Loading states during save

**Files to Modify:**
- `PetSafety/PetSafety/Views/Profile/ProfileView.swift`

**Reference:**
- Web implementation in `src/pages/Settings.tsx`

---

#### 5. Backend - Nearby Alerts Optimization
**Status:** 🟡 Needs Performance Review
**Platforms:** Backend

**Requirements:**
- Review PostGIS query performance
- Add database index on (latitude, longitude) columns
- Consider caching frequently accessed alerts
- Add pagination for large result sets
- Monitor query execution time

**Files to Check:**
- Alert model and controller
- Database migration for spatial index
- Redis caching layer

---

#### 6. Test Location Sharing End-to-End
**Status:** 🟡 Needs Testing
**Platforms:** All

**Test Scenarios:**
1. **Web Finder Flow:**
   - Scan QR on public profile page
   - Allow location permission
   - Click "Share Location"
   - Verify owner receives SMS + Email
   - Check map link in notifications works
   - Verify correct GPS coordinates

2. **iOS Finder Flow:**
   - Scan QR with in-app scanner
   - ShareLocationView appears
   - Location captured correctly
   - Notifications sent
   - Verify with test phone numbers

3. **Privacy Settings:**
   - Owner turns off phone visibility
   - Finder scans QR
   - Phone number should NOT appear
   - Call button should NOT appear
   - Email still works if enabled

4. **Edge Cases:**
   - Location permission denied
   - Network failure during share
   - Invalid QR code
   - Owner has no phone number
   - International phone numbers (E.164 format)

**Documentation Needed:**
- Test plan spreadsheet
- Bug tracking
- User acceptance criteria

---

#### 7. SMS & Email Templates
**Status:** 🟡 Basic Implementation
**Platforms:** Backend

**Current State:**
- Basic notification templates exist
- Need improvement for clarity and branding

**Requirements:**
- **Tag Scanned Notification:**
  - Subject: "🐾 [Pet Name]'s tag was just scanned!"
  - Body: Include timestamp, basic instructions
  - Call-to-action: "View details" link

- **Location Shared Notification:**
  - Subject: "📍 [Pet Name] was spotted nearby!"
  - Body: Address, Google Maps link, timestamp
  - Clear map preview (if email)
  - SMS: Short format with map link

- **Sighting Reported Notification:**
  - Include reporter's contact (if provided)
  - Photos if attached
  - Notes from finder

- **Alert Created Confirmation:**
  - Owner receives confirmation when alert goes live
  - Estimated reach (users in 10km)

**Files to Modify:**
- Email templates: HTML + Plain text versions
- SMS templates: Character limit optimization
- Add template variables for personalization

---

#### 8. Error Handling & User Feedback
**Status:** 🟡 Partial
**Platforms:** All

**Requirements:**
- **Network Errors:**
  - Graceful offline handling
  - Retry mechanism for failed location shares
  - Queue notifications when offline

- **Permission Errors:**
  - Clear instructions when location denied
  - Link to device settings
  - Alternative contact methods

- **Validation Errors:**
  - Field-level validation on forms
  - Clear error messages
  - Prevent submission until valid

- **Success States:**
  - Confirmation messages for all actions
  - Loading indicators during async operations
  - Toast notifications with appropriate duration

**Files to Audit:**
- All view models and API services
- Form components
- Error boundary components

---

### MEDIUM PRIORITY

#### 9. Push Notifications (iOS)
**Status:** 🔴 Not Started
**Platforms:** iOS + Backend

**Requirements:**
- APNs integration
- Device token registration
- Notification permissions flow
- Silent notifications for alert updates
- Rich notifications with pet photo
- Actionable notifications ("View Location", "Mark as Found")

**Files to Create:**
- `PetSafety/PetSafety/Services/PushNotificationService.swift`
- Backend: APNs sender service

---

#### 10. Improved Photo Upload
**Status:** 🟡 Basic Implementation
**Platforms:** Web + iOS

**Requirements:**
- Image compression before upload
- Multiple photo angles per pet
- Photo gallery view
- Crop/rotate tools
- Loading progress indicator
- Preview before upload

---

#### 11. Search & Filter Alerts
**Status:** 🔴 Not Started
**Platforms:** Web + iOS

**Requirements:**
- Search by pet name, breed, color
- Filter by species (dog/cat/other)
- Filter by date range
- Sort by distance, date
- Save search preferences

---

#### 12. Alert Sighting History
**Status:** 🟡 Partial
**Platforms:** Web + iOS + Backend

**Current State:**
- Sightings stored in database
- Not displayed in detail view

**Requirements:**
- Timeline view of all sightings
- Map with all sighting locations
- Contact info of reporters (if provided)
- Photos from sightings
- Chronological order

---

#### 13. User Dashboard Analytics
**Status:** 🔴 Not Started
**Platforms:** Web + iOS

**Requirements:**
- Number of scans per pet
- Alert views count
- Location shares count
- Successful reunions
- Graphs over time

---

#### 14. QR Tag Ordering System
**Status:** 🔴 Not Started
**Platforms:** Web + Backend

**Requirements:**
- Physical tag product catalog
- Shopping cart
- Stripe checkout for products (not just subscriptions)
- Shipping address collection
- Order tracking
- Integration with print-on-demand service

---

#### 15. Notification Preferences
**Status:** 🔴 Not Started
**Platforms:** Web + iOS + Backend

**Requirements:**
- Opt-in/out for email notifications
- Opt-in/out for SMS notifications
- Opt-in/out for push notifications
- Notification frequency settings
- Quiet hours

---

#### 16. Pet Medical Records
**Status:** 🟡 Basic Notes Field
**Platforms:** All

**Enhancement:**
- Structured medical info (vaccinations, allergies, medications)
- Vet contact information
- Emergency medical instructions visible on public profile
- File attachments for medical documents

---

#### 17. Multi-language Support
**Status:** 🔴 Not Started
**Platforms:** All

**Requirements:**
- i18n setup (React: react-i18next, iOS: Localizable.strings)
- Language switcher in settings
- Translations for: English, Spanish, French, German, Italian
- RTL support for Arabic/Hebrew
- Date/time localization

---

### LOW PRIORITY

#### 18. Social Sharing
**Status:** 🔴 Not Started
**Platforms:** Web + iOS

**Requirements:**
- Share missing pet alert to Facebook, Twitter, WhatsApp
- Pre-filled post with pet photo and details
- Link back to public profile
- Track shares and engagement

---

#### 19. Pet Microchip Integration
**Status:** 🔴 Not Started
**Platforms:** All

**Requirements:**
- Add microchip number field
- Link to international microchip databases
- Cross-reference found pets with microchip registries
- API integration with PetLink, HomeAgain, etc.

---

#### 20. Community Features
**Status:** 🔴 Not Started
**Platforms:** All

**Requirements:**
- Comments on alerts (moderated)
- Thank you messages from reunited owners
- Success story wall
- User reputation system
- Report inappropriate content

---

#### 21. Pet Insurance Partnerships
**Status:** 🔴 Not Started
**Platforms:** Web

**Requirements:**
- Affiliate partnerships with pet insurance providers
- Special offers for platform users
- Insurance quote comparison
- Revenue sharing model

---

#### 22. Vet Finder
**Status:** 🔴 Not Started
**Platforms:** Web + iOS

**Requirements:**
- Directory of nearby veterinary clinics
- Emergency 24/7 vets
- Map integration
- Call/directions buttons
- Reviews and ratings

---

#### 23. Pet Walker/Sitter Directory
**Status:** 🔴 Not Started
**Platforms:** Web + iOS

**Requirements:**
- Verified pet service providers
- Booking system
- Background checks
- Reviews and ratings
- In-app messaging

---

#### 24. Analytics Dashboard (Admin)
**Status:** 🔴 Not Started
**Platforms:** Web (Admin Panel)

**Requirements:**
- Total users, pets, alerts
- Successful reunions rate
- Most scanned tags
- Geographic heatmap
- Revenue metrics
- User retention charts

---

#### 25. Advanced Map Features
**Status:** 🔴 Not Started
**Platforms:** Web + iOS

**Requirements:**
- Heatmap of missing pet density
- Last known path (multiple sightings)
- Geofence alerts (notify when pet spotted in area)
- Offline map caching
- Custom map styles

---

#### 26. Apple Watch App
**Status:** 🔴 Not Started
**Platform:** watchOS

**Requirements:**
- Quick QR scanner from watch
- Alert notifications on watch
- "Mark as Found" quick action
- Nearby missing pets glance
- Complications for watch faces

---

### TECHNICAL DEBT

#### Code Quality
- [ ] Add comprehensive unit tests (Web: Jest, iOS: XCTest)
- [ ] Add integration tests for critical flows
- [ ] Add E2E tests (Web: Playwright/Cypress)
- [ ] Code coverage >80%
- [ ] Linting and formatting consistency
- [ ] Type safety improvements (eliminate `any` types)
- [ ] API response schema validation

#### Performance
- [ ] Lazy loading for images
- [ ] Code splitting (Web)
- [ ] Bundle size optimization
- [ ] Database query optimization
- [ ] CDN for static assets
- [ ] Image optimization (WebP, srcset)
- [ ] Redis caching strategy

#### Security
- [ ] Security audit
- [ ] Penetration testing
- [ ] Rate limiting on all endpoints
- [ ] Input sanitization review
- [ ] SQL injection prevention audit
- [ ] XSS prevention review
- [ ] CSRF token implementation
- [ ] Content Security Policy headers
- [ ] Secrets rotation policy

#### Documentation
- [ ] API documentation (Swagger/OpenAPI)
- [ ] Code commenting standards
- [ ] Architecture decision records (ADRs)
- [ ] Deployment runbook
- [ ] Incident response playbook
- [ ] User guides and FAQs
- [ ] Video tutorials

---

## Technical Architecture

### Frontend Stack

#### Web App
- **Framework:** React 18.3.1 with TypeScript 5.6.3
- **Build Tool:** Vite 6.0.1
- **Routing:** React Router v6
- **UI Library:** Shadcn/ui (Radix UI primitives)
- **Styling:** Tailwind CSS 3.4.1
- **HTTP Client:** Axios
- **State Management:** React Context + Hooks
- **Forms:** React Hook Form + Zod validation
- **Notifications:** Sonner (toast notifications)

#### iOS App
- **Framework:** SwiftUI (iOS 15+)
- **Language:** Swift 5.9+
- **Architecture:** MVVM (Model-View-ViewModel)
- **Networking:** URLSession with async/await
- **Authentication:** Firebase Auth
- **Location:** CoreLocation
- **Maps:** MapKit
- **Camera:** AVFoundation (QR scanning)
- **Storage:** UserDefaults + Keychain
- **Image Loading:** AsyncImage

### Backend Stack
- **Runtime:** Node.js 18+
- **Framework:** Express.js with TypeScript
- **Database:** PostgreSQL 14+ with PostGIS extension
- **ORM:** Likely Sequelize or raw SQL
- **Authentication:** JWT tokens
- **File Storage:** AWS S3
- **Email:** AWS SES
- **SMS:** AWS SNS / Amazon Pinpoint
- **Payments:** Stripe API
- **Caching:** Redis (for sessions, frequently accessed data)
- **API Format:** RESTful JSON

### Database Schema (Key Tables)

#### Users
- `id` (UUID, PK)
- `email` (unique, indexed)
- `password_hash`
- `name`
- `phone`
- `address` (TODO: expand to full address fields)
- `show_phone_publicly` (boolean, default true)
- `show_email_publicly` (boolean, default true)
- `subscription_tier` (free/premium)
- `subscription_end_date`
- `created_at`, `updated_at`

#### Pets
- `id` (UUID, PK)
- `user_id` (FK to users)
- `name`
- `species` (dog/cat/other)
- `breed`
- `color`
- `age`
- `weight`
- `photo_url` (S3 URL)
- `medical_info` (text)
- `special_notes` (text)
- `qr_code` (unique, indexed)
- `status` (normal/lost/found)
- `created_at`, `updated_at`

#### Alerts (Missing Pet Reports)
- `id` (UUID, PK)
- `pet_id` (FK to pets)
- `user_id` (FK to users)
- `status` (active/resolved)
- `last_seen_location` (text address)
- `last_seen_latitude` (decimal)
- `last_seen_longitude` (decimal)
- `additional_info` (text)
- `created_at` (when reported missing)
- `updated_at` (when marked found)
- PostGIS index on (latitude, longitude) for radius queries

#### Sightings (Location Shares)
- `id` (UUID, PK)
- `alert_id` (FK to alerts, nullable)
- `pet_id` (FK to pets)
- `qr_code` (indexed)
- `latitude` (decimal)
- `longitude` (decimal)
- `address` (text, from reverse geocoding)
- `reporter_name` (optional)
- `reporter_phone` (optional)
- `reporter_email` (optional)
- `notes` (optional)
- `created_at` (timestamp of sighting)

#### Subscriptions
- `id` (UUID, PK)
- `user_id` (FK to users)
- `stripe_customer_id`
- `stripe_subscription_id`
- `plan` (monthly/annual)
- `status` (active/canceled/past_due)
- `current_period_start`
- `current_period_end`
- `created_at`, `updated_at`

### API Endpoints (Selected)

#### Authentication
- `POST /auth/register` - Create new user account
- `POST /auth/login` - Login with email/password
- `POST /auth/logout` - Invalidate token
- `POST /auth/forgot-password` - Request password reset
- `POST /auth/reset-password` - Reset password with token

#### Users
- `GET /users/me` - Get current user profile
- `PATCH /users/me` - Update profile (includes privacy settings)
- `DELETE /users/me` - Delete account

#### Pets
- `GET /pets` - List user's pets
- `POST /pets` - Create new pet
- `GET /pets/:id` - Get pet details
- `PATCH /pets/:id` - Update pet
- `DELETE /pets/:id` - Delete pet
- `POST /pets/:id/mark-lost` - Mark pet as lost (creates alert)
- `POST /pets/:id/mark-found` - Mark pet as found (resolves alert)

#### QR Tags
- `GET /qr-tags/scan/:qrCode` - Get public pet profile (NO AUTH)
- `POST /qr-tags/activate` - Link tag to pet
- `POST /qr-tags/share-location` - Finder shares location (NO AUTH)

#### Alerts
- `GET /alerts` - List user's alerts
- `GET /alerts/nearby` - Get alerts within radius (NO AUTH)
  - Query params: `lat`, `lng`, `radius` (km)
- `POST /alerts` - Create alert (or use mark-lost)
- `PATCH /alerts/:id/status` - Update alert status
- `POST /alerts/:id/sightings` - Report sighting

#### Subscriptions
- `GET /subscriptions/me` - Get current subscription
- `POST /subscriptions/create-checkout` - Create Stripe checkout session
- `POST /subscriptions/create-portal` - Create Stripe customer portal session
- `POST /webhooks/stripe` - Handle Stripe webhooks

### Deployment Architecture

#### Web App
- **Hosting:** Vercel, Netlify, or AWS Amplify
- **CDN:** Cloudflare or AWS CloudFront
- **Environment:** Production, Staging, Development

#### iOS App
- **Distribution:** Apple App Store
- **TestFlight:** For beta testing
- **App Store Connect:** For releases

#### Backend
- **Hosting:** AWS EC2, Google Cloud Run, or Heroku
- **Database:** Managed PostgreSQL (AWS RDS, Google Cloud SQL)
- **Redis:** AWS ElastiCache or Redis Cloud
- **Load Balancer:** AWS ALB or Google Cloud LB
- **Monitoring:** CloudWatch, Sentry for error tracking
- **CI/CD:** GitHub Actions

### Security Measures
- JWT tokens with short expiration (15 min access, 7 day refresh)
- Passwords hashed with bcrypt (10+ rounds)
- HTTPS only (SSL/TLS certificates)
- CORS configured for allowed origins
- Rate limiting on sensitive endpoints
- Input validation on all user inputs
- SQL parameterized queries (prevent injection)
- S3 bucket policies (private by default, signed URLs for uploads)
- Environment variables for secrets (never committed)

### Monitoring & Analytics
- **Application Monitoring:** Sentry, Datadog, or New Relic
- **User Analytics:** Google Analytics, Mixpanel, or Amplitude
- **Error Tracking:** Sentry
- **Uptime Monitoring:** Pingdom, UptimeRobot
- **Log Aggregation:** CloudWatch Logs, Loggly, or Papertrail

---

## Conclusion

The Pet Safety Platform is a comprehensive solution with strong foundations in place. The core QR tag scanning, location sharing, and privacy controls are implemented across web and iOS platforms.

### Key Achievements
✅ Robust authentication and user management
✅ Complete pet profile system with photo uploads
✅ QR code generation and scanning
✅ Real-time location sharing with SMS/Email notifications
✅ Privacy-first contact information controls
✅ iOS Alerts system with Missing/Found tabs and Map/List views
✅ Stripe subscription management

### Immediate Next Steps
1. Implement user registered address fields
2. Build web app Alerts page (matching iOS)
3. Complete "Mark as Found" functionality
4. Add iOS privacy settings view
5. Comprehensive end-to-end testing
6. Performance optimization for nearby alerts queries

### Long-term Vision
- Expand to Apple Watch, Android platforms
- Build community features and success stories
- Partner with pet insurance and service providers
- International expansion with multi-language support
- Advanced map features with geofencing and heatmaps

---

**Document Version:** 1.0
**Last Updated:** November 23, 2025
**Maintained by:** Development Team
**For questions:** Contact project maintainer