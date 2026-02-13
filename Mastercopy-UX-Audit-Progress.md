# UX Audit Progress - Pet Safety Platform

## Project Locations
- **Android**: `/Users/viktorszasz/pet-safety-android/`
- **iOS**: `/Users/viktorszasz/pet-safety-ios/`
- **Web/Backend**: `/Users/viktorszasz/Project-Xtag/`

## Completed Tasks

### 1. Fix Contacts Save Button (Android) - DONE
- `app/src/main/java/com/petsafety/app/data/model/User.kt` - Added `secondaryPhone` and `secondaryEmail` fields
- `app/src/main/java/com/petsafety/app/ui/screens/ProfileScreen.kt` - Rewrote ContactsScreen with Save button, loading state, API persistence

### 2. Add Confirmation Dialogs for Mark as Found (iOS + Android) - DONE
- iOS: `PetDetailView.swift` and `QuickMarkFoundView.swift` - Added confirmation alerts before marking found
- Android: `PetDetailScreen.kt` and `MarkLostFoundSheet.kt` - Added AlertDialog confirmations

### 3. Fix Registration Flow (iOS + Android) - PARTIALLY DONE
**iOS - COMPLETE:**
- Created `Views/Auth/RegistrationView.swift` - Full registration form with OTP
- Edited `Views/Auth/AuthenticationView.swift` - Added `onNavigateToRegister` property and Register link
- Edited `App/ContentView.swift` - Added `showRegistration` state and routing

**Android - PARTIALLY DONE:**
- `res/values/strings.xml` - All needed strings already added (create_account, enter_details_subtitle, first_name, last_name, register, already_have_account, log_in)
- `ui/PetSafetyApp.kt` - Already has `showRegisterScreen` state and routing to `RegisterScreen`
- `ui/AuthScreen.kt` - Already has `onNavigateToRegister` parameter AND the Register TextButton (line ~494)
- **NOT DONE: `ui/RegisterScreen.kt` needs to be CREATED** (see details below)

### 5. Add OTP Resend Button + Timer (iOS + Android) - DONE
- iOS: `AuthenticationView.swift` - Added resendCooldown timer and resend button
- Android: `AuthScreen.kt` - Added resendCooldown with LaunchedEffect and resend button

### 6. Fix Session Expiration UI (Android) - DONE
- `res/values/strings.xml` - Added session_expired strings
- `ui/viewmodel/AuthViewModel.kt` - Added `authRepository.logout()` in expiration handler
- `ui/PetSafetyApp.kt` - Added non-dismissible session expired AlertDialog

---

## IMMEDIATE NEXT: Create Android RegisterScreen.kt

**File to create:** `/Users/viktorszasz/pet-safety-android/app/src/main/java/com/petsafety/app/ui/RegisterScreen.kt`

This screen is already wired into navigation in PetSafetyApp.kt (line 145-149):
```kotlin
RegisterScreen(
    appStateViewModel = appStateViewModel,
    authViewModel = authViewModel,
    onNavigateToLogin = { showRegisterScreen = false }
)
```

**Registration flow:**
1. Collects First Name (required), Last Name (optional), Email (required)
2. "Create Account" button calls `authViewModel.login(email, onSuccess, onFailure)` to send OTP
3. OTP verification calls `authViewModel.verifyOtp(email, code, onSuccess, onFailure)`
4. After verify, calls `authViewModel.updateProfile(mapOf("first_name" to firstName, "last_name" to lastName)) { _, _ -> }`
5. "Already have an account? Log in" link calls `onNavigateToLogin`

**Key notes:**
- NO `ic_person` drawable exists - use `Icons.Default.Person` from Material Icons
- `R.drawable.ic_email` and `R.drawable.logo_new` DO exist
- Match AuthScreen.kt styling: RoundedCornerShape(40.dp) card, PeachBackground, 28.dp padding, 14.dp rounded inputs with white background
- Use existing string resources: R.string.create_account, R.string.enter_details_subtitle, R.string.first_name, R.string.last_name, R.string.email_address, R.string.verify_code, R.string.otp_sent_to, R.string.use_different_email, R.string.already_have_account, R.string.log_in
- Use existing theme: BackgroundLight, BrandOrange, MutedTextLight, PeachBackground, BrandButton, AdaptiveLayout.MaxContentWidth
- Include T&Cs disclaimer with clickable Terms (https://senra.pet/terms) and Privacy (https://senra.pet/privacy) links
- Reference AuthScreen.kt for exact styling patterns

---

## Remaining Tasks (Priority Order)

### High Priority
4. **Implement "Report Sighting" functionality** - All platforms need the full sighting report flow
8. **Add inline form validation** - Email format, required fields, phone format across all platforms
12. **Fix dead-end links and non-functional buttons** - Audit all platforms for broken links

### Medium Priority
7. **Implement real geocoding for alerts (Web)** - Replace placeholder coordinates
9. **Implement real map views (iOS + Web)** - iOS uses MapKit, Web needs proper map component
10. **Add dark mode support (Android)** - Currently only light theme
11. **Add flashlight toggle to QR scanner (Android)** - Missing from scanner screen
13. **Add accessibility labels (iOS + Android)** - contentDescription on Android, accessibilityLabel on iOS
14. **Remove console.log and placeholder content (Web)** - Clean up for production
15. **Fix Premium badge - only show for subscribers (iOS)** - Currently shows for all users
16. **Add photo upload progress indicator (iOS)** - No feedback during upload
17. **Add error retry mechanisms (all platforms)** - Retry buttons on failed network requests
18. **Fix email validation (Web)** - Weak regex validation
19. **Replace browser confirm() dialogs with styled modals (Web)**
20. **Add order confirmation page (Web)**
21. **Fix Starter plan dead-end UX (Web)** - Selecting starter plan leads nowhere
24. **Sync notification preferences to backend (iOS)** - Currently local-only toggles

### Low Priority
22. **Add animations and transitions (iOS + Android)**
23. **Add haptic feedback (iOS + Android)**
25. **Add search and filter to pet/alert lists (all platforms)**
26. **Add breadcrumb navigation to multi-step flows (Web)**
27. **Add offline sync status visibility (Android)**
28. **Add splash screen (Android)**

---

## Architecture Notes

- **Auth flow**: OTP-based passwordless. `POST /auth/send-otp` sends code, `POST /auth/verify-otp` verifies and auto-creates users. Registration uses same flow + `PATCH /users/me` for name.
- **Android**: Jetpack Compose, Material 3, Hilt DI, MVVM, StateFlow
- **iOS**: SwiftUI, MVVM, EnvironmentObject
- **Web**: React + Radix UI, Node.js backend
- **API base**: https://senra.pet/api
- **Stripe**: Not yet implemented (skip subscription tasks)
