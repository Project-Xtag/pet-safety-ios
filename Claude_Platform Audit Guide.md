# Platform Audit Guide

## Project Structure

```
├── pet-safety-ios/        # iOS mobile app (Swift/SwiftUI)
├── pet-safety-android/    # Android mobile app (Kotlin)
└── project-Xtag/          # Backend server + Web application
```

## Audit Objectives

1. **Security vulnerabilities** - authentication, authorization, data exposure, injection attacks
2. **Flow completeness** - identify missing, broken, or unfinished user flows
3. **Cross-platform parity** - differences between iOS, Android, and Web implementations
4. **Data integrity** - untracked fields, missing migrations, schema inconsistencies
5. **Production readiness** - error handling, logging, environment configs

**Known Incomplete:** Stripe payments, Google Maps integration

---

## 1. SECURITY AUDIT

### 1.1 Authentication & Session Management

#### Backend (project-Xtag)
```
Files to check:
- auth controllers/routes
- middleware/authentication
- JWT/session configuration
- password reset handlers
```

| Check | Status | Notes |
|-------|--------|-------|
| JWT secret strength (min 256-bit) | ⬜ | |
| Token expiry configured (access: 15-60min, refresh: 7-30 days) | ⬜ | |
| Refresh token rotation implemented | ⬜ | |
| Refresh tokens stored securely (DB, not just memory) | ⬜ | |
| Password hashing (bcrypt cost ≥10 or argon2id) | ⬜ | |
| Rate limiting on /login, /register, /forgot-password | ⬜ | |
| Account lockout after N failed attempts | ⬜ | |
| Session invalidation on password change | ⬜ | |
| Password reset tokens time-limited (<1 hour) | ⬜ | |
| Password reset tokens single-use | ⬜ | |
| Email verification flow complete | ⬜ | |
| Logout invalidates tokens server-side | ⬜ | |

#### iOS App (pet-safety-ios)
| Check | Status | Notes |
|-------|--------|-------|
| Tokens stored in Keychain (not UserDefaults) | ⬜ | |
| Biometric auth integration (if applicable) | ⬜ | |
| Token refresh handled automatically | ⬜ | |
| Secure handling of auth state on app backgrounding | ⬜ | |
| Certificate pinning implemented | ⬜ | |
| Jailbreak detection (optional but recommended) | ⬜ | |

#### Android App (pet-safety-android)
| Check | Status | Notes |
|-------|--------|-------|
| Tokens stored in EncryptedSharedPreferences or Keystore | ⬜ | |
| Biometric auth integration (if applicable) | ⬜ | |
| Token refresh handled automatically | ⬜ | |
| ProGuard/R8 obfuscation enabled for release | ⬜ | |
| Certificate pinning implemented | ⬜ | |
| Root detection (optional but recommended) | ⬜ | |
| android:allowBackup="false" in manifest | ⬜ | |

#### Web App (project-Xtag)
| Check | Status | Notes |
|-------|--------|-------|
| Tokens stored in httpOnly cookies (preferred) or secure storage | ⬜ | |
| CSRF protection implemented | ⬜ | |
| XSS prevention (sanitized inputs, CSP headers) | ⬜ | |
| Secure cookie flags (Secure, SameSite) | ⬜ | |

---

### 1.2 API Security

#### Endpoint Protection
| Check | Status | Notes |
|-------|--------|-------|
| All sensitive endpoints require authentication | ⬜ | |
| Role-based access control (RBAC) implemented | ⬜ | |
| Users can only access their own resources (IDOR prevention) | ⬜ | |
| Admin endpoints properly protected | ⬜ | |
| API versioning in place | ⬜ | |

#### Input Validation & Sanitization
| Check | Status | Notes |
|-------|--------|-------|
| SQL injection prevention (parameterized queries/ORM) | ⬜ | |
| NoSQL injection prevention (if applicable) | ⬜ | |
| Request body validation (Joi, Zod, class-validator, etc.) | ⬜ | |
| File upload validation (type, size, content) | ⬜ | |
| Path traversal prevention | ⬜ | |
| Command injection prevention | ⬜ | |

#### Response Security
| Check | Status | Notes |
|-------|--------|-------|
| Sensitive data not leaked in responses (passwords, tokens) | ⬜ | |
| Error messages don't expose system internals | ⬜ | |
| Proper HTTP status codes used | ⬜ | |
| CORS configured correctly (not wildcard in production) | ⬜ | |
| Security headers set (X-Content-Type-Options, X-Frame-Options, etc.) | ⬜ | |

---

### 1.3 Data Security

#### Database
| Check | Status | Notes |
|-------|--------|-------|
| Sensitive fields encrypted at rest (PII, health data) | ⬜ | |
| Database connection uses SSL | ⬜ | |
| Database credentials not hardcoded | ⬜ | |
| Principle of least privilege for DB user | ⬜ | |
| Soft delete vs hard delete strategy documented | ⬜ | |

#### File Storage (S3/Cloud)
| Check | Status | Notes |
|-------|--------|-------|
| Buckets not publicly accessible | ⬜ | |
| Pre-signed URLs used for uploads/downloads | ⬜ | |
| File type validation before upload | ⬜ | |
| Malware scanning (if applicable) | ⬜ | |

#### Secrets Management
| Check | Status | Notes |
|-------|--------|-------|
| No secrets in source code | ⬜ | |
| .env files in .gitignore | ⬜ | |
| Different secrets per environment | ⬜ | |
| API keys rotatable | ⬜ | |

---

## 2. USER FLOW AUDIT

### 2.1 Authentication Flows

| Flow | iOS | Android | Web | Backend | Notes |
|------|-----|---------|-----|---------|-------|
| Registration (email/password) | ⬜ | ⬜ | ⬜ | ⬜ | |
| Registration (social - Apple) | ⬜ | N/A | ⬜ | ⬜ | |
| Registration (social - Google) | ⬜ | ⬜ | ⬜ | ⬜ | |
| Login (email/password) | ⬜ | ⬜ | ⬜ | ⬜ | |
| Login (social - Apple) | ⬜ | N/A | ⬜ | ⬜ | |
| Login (social - Google) | ⬜ | ⬜ | ⬜ | ⬜ | |
| Forgot password request | ⬜ | ⬜ | ⬜ | ⬜ | |
| Password reset completion | ⬜ | ⬜ | ⬜ | ⬜ | |
| Email verification | ⬜ | ⬜ | ⬜ | ⬜ | |
| Logout | ⬜ | ⬜ | ⬜ | ⬜ | |
| Delete account | ⬜ | ⬜ | ⬜ | ⬜ | |
| Change password | ⬜ | ⬜ | ⬜ | ⬜ | |
| Change email | ⬜ | ⬜ | ⬜ | ⬜ | |

### 2.2 Core Feature Flows

> **Instructions:** List all major features and check implementation status across platforms

| Flow | iOS | Android | Web | Backend | Notes |
|------|-----|---------|-----|---------|-------|
| [Feature 1: e.g., Pet Profile CRUD] | ⬜ | ⬜ | ⬜ | ⬜ | |
| [Feature 2: e.g., QR Tag Registration] | ⬜ | ⬜ | ⬜ | ⬜ | |
| [Feature 3: e.g., Emergency Contact] | ⬜ | ⬜ | ⬜ | ⬜ | |
| [Feature 4] | ⬜ | ⬜ | ⬜ | ⬜ | |
| [Feature 5] | ⬜ | ⬜ | ⬜ | ⬜ | |

### 2.3 Profile & Settings Flows

| Flow | iOS | Android | Web | Backend | Notes |
|------|-----|---------|-----|---------|-------|
| View profile | ⬜ | ⬜ | ⬜ | ⬜ | |
| Edit profile | ⬜ | ⬜ | ⬜ | ⬜ | |
| Upload avatar/photo | ⬜ | ⬜ | ⬜ | ⬜ | |
| Notification preferences | ⬜ | ⬜ | ⬜ | ⬜ | |
| Language/locale settings | ⬜ | ⬜ | ⬜ | ⬜ | |
| Privacy settings | ⬜ | ⬜ | ⬜ | ⬜ | |

### 2.4 Subscription/Payment Flows (Stripe - NOT IMPLEMENTED)

| Flow | iOS | Android | Web | Backend | Notes |
|------|-----|---------|-----|---------|-------|
| View subscription plans | ⬜ | ⬜ | ⬜ | ⬜ | NOT IMPLEMENTED |
| Subscribe/purchase | ⬜ | ⬜ | ⬜ | ⬜ | NOT IMPLEMENTED |
| Cancel subscription | ⬜ | ⬜ | ⬜ | ⬜ | NOT IMPLEMENTED |
| Update payment method | ⬜ | ⬜ | ⬜ | ⬜ | NOT IMPLEMENTED |
| View billing history | ⬜ | ⬜ | ⬜ | ⬜ | NOT IMPLEMENTED |
| Handle failed payments | ⬜ | ⬜ | ⬜ | ⬜ | NOT IMPLEMENTED |
| Webhook handling | N/A | N/A | N/A | ⬜ | NOT IMPLEMENTED |

### 2.5 Map/Location Flows (Google Maps - NOT IMPLEMENTED)

| Flow | iOS | Android | Web | Backend | Notes |
|------|-----|---------|-----|---------|-------|
| Display map | ⬜ | ⬜ | ⬜ | N/A | NOT IMPLEMENTED |
| Location search | ⬜ | ⬜ | ⬜ | ⬜ | NOT IMPLEMENTED |
| Geocoding/reverse geocoding | ⬜ | ⬜ | ⬜ | ⬜ | NOT IMPLEMENTED |
| Location permissions handling | ⬜ | ⬜ | ⬜ | N/A | NOT IMPLEMENTED |

---

## 3. CROSS-PLATFORM PARITY AUDIT

### 3.1 Feature Parity Matrix

> Fill in all features and mark implementation status

| Feature | iOS | Android | Web | Parity Issue? |
|---------|-----|---------|-----|---------------|
| | | | | |
| | | | | |
| | | | | |

### 3.2 UI/UX Consistency

| Element | iOS | Android | Web | Notes |
|---------|-----|---------|-----|-------|
| Error message wording identical | ⬜ | ⬜ | ⬜ | |
| Validation rules identical | ⬜ | ⬜ | ⬜ | |
| Loading states present | ⬜ | ⬜ | ⬜ | |
| Empty states present | ⬜ | ⬜ | ⬜ | |
| Offline handling | ⬜ | ⬜ | ⬜ | |
| Pull-to-refresh (where applicable) | ⬜ | ⬜ | N/A | |
| Pagination/infinite scroll | ⬜ | ⬜ | ⬜ | |
| Form field order matches | ⬜ | ⬜ | ⬜ | |
| Required field indicators | ⬜ | ⬜ | ⬜ | |

### 3.3 API Usage Consistency

> Document which endpoints each platform calls for the same feature

| Feature/Flow | iOS Endpoints | Android Endpoints | Web Endpoints | Mismatch? |
|--------------|---------------|-------------------|---------------|-----------|
| Login | | | | |
| Register | | | | |
| Get Profile | | | | |
| Update Profile | | | | |
| | | | | |

### 3.4 Data Model Consistency

> Check if all platforms send/receive the same fields

| Endpoint | iOS Fields | Android Fields | Web Fields | Discrepancy |
|----------|------------|----------------|------------|-------------|
| POST /auth/register | | | | |
| POST /auth/login | | | | |
| GET /user/profile | | | | |
| PUT /user/profile | | | | |
| | | | | |

---

## 4. DATABASE & DATA INTEGRITY AUDIT

### 4.1 Schema Review

```
Files to check:
- migrations/
- models/
- schema definitions
- seed files
- prisma/schema.prisma or equivalent
```

| Check | Status | Notes |
|-------|--------|-------|
| All tables have primary keys | ⬜ | |
| Foreign key constraints in place | ⬜ | |
| Indexes on frequently queried columns | ⬜ | |
| Created/updated timestamps on all tables | ⬜ | |
| Soft delete columns where needed | ⬜ | |
| No orphaned tables/columns | ⬜ | |
| Enum values match application constants | ⬜ | |
| Nullable fields intentionally nullable | ⬜ | |

### 4.2 Migration Health

| Check | Status | Notes |
|-------|--------|-------|
| All migrations reversible (up/down) | ⬜ | |
| No breaking migrations without data migration | ⬜ | |
| Migration naming convention consistent | ⬜ | |
| No direct SQL in code (use migrations) | ⬜ | |
| Seed data up to date | ⬜ | |
| Migration order is correct | ⬜ | |
| No duplicate migrations | ⬜ | |

### 4.3 Data Tracking & Audit Fields

| Table/Entity | created_at | updated_at | deleted_at | created_by | updated_by | Notes |
|--------------|------------|------------|------------|------------|------------|-------|
| users | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | |
| | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | |
| | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | |
| | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | |

### 4.4 Data Relationships

| Parent Table | Child Table | Relationship | Cascade Delete? | Orphan Risk? |
|--------------|-------------|--------------|-----------------|--------------|
| users | | | | |
| | | | | |
| | | | | |

### 4.5 Data Consistency Issues Found

| Issue | Severity | Description | Resolution |
|-------|----------|-------------|------------|
| | | | |

---

## 5. ERROR HANDLING & LOGGING

### 5.1 Backend Error Handling

| Check | Status | Notes |
|-------|--------|-------|
| Global error handler implemented | ⬜ | |
| Async errors caught properly (try/catch or middleware) | ⬜ | |
| Database errors handled gracefully | ⬜ | |
| External service errors handled (AWS, Firebase, etc.) | ⬜ | |
| Validation errors return 400 with details | ⬜ | |
| Auth errors return 401/403 appropriately | ⬜ | |
| Not found errors return 404 | ⬜ | |
| Server errors return 500 without stack trace | ⬜ | |
| Unhandled promise rejections caught | ⬜ | |
| Uncaught exceptions handled | ⬜ | |

### 5.2 Logging

| Check | Status | Notes |
|-------|--------|-------|
| Structured logging (JSON format) | ⬜ | |
| Log levels used appropriately (error, warn, info, debug) | ⬜ | |
| Request/response logging (with sensitive data redacted) | ⬜ | |
| Error stack traces logged server-side | ⬜ | |
| User actions logged for audit trail | ⬜ | |
| No sensitive data in logs (passwords, tokens, PII) | ⬜ | |
| Log rotation/retention configured | ⬜ | |
| Correlation IDs for request tracing | ⬜ | |

### 5.3 Mobile App Error Handling

| Check | iOS | Android | Notes |
|-------|-----|---------|-------|
| Network errors handled gracefully | ⬜ | ⬜ | |
| Timeout handling | ⬜ | ⬜ | |
| Retry logic for transient failures | ⬜ | ⬜ | |
| User-friendly error messages | ⬜ | ⬜ | |
| Crash reporting integrated (Crashlytics, Sentry) | ⬜ | ⬜ | |
| Analytics events tracked | ⬜ | ⬜ | |
| Graceful degradation when offline | ⬜ | ⬜ | |
| HTTP error codes handled correctly | ⬜ | ⬜ | |

### 5.4 Web App Error Handling

| Check | Status | Notes |
|-------|--------|-------|
| Global error boundary | ⬜ | |
| API error handling | ⬜ | |
| Form validation errors | ⬜ | |
| 404 page exists | ⬜ | |
| 500 error page exists | ⬜ | |
| Error tracking (Sentry, etc.) | ⬜ | |

---

## 6. ENVIRONMENT & CONFIGURATION

### 6.1 Environment Separation

| Check | Status | Notes |
|-------|--------|-------|
| Separate configs for dev/staging/prod | ⬜ | |
| No production credentials in dev | ⬜ | |
| Feature flags for incomplete features | ⬜ | |
| Environment-specific API URLs | ⬜ | |
| Database per environment | ⬜ | |

### 6.2 Backend Configuration

| Check | Status | Notes |
|-------|--------|-------|
| All config via environment variables | ⬜ | |
| .env.example file exists | ⬜ | |
| Required env vars validated on startup | ⬜ | |
| Graceful shutdown handling | ⬜ | |
| Health check endpoint | ⬜ | |

### 6.3 iOS Build Configuration

| Check | Status | Notes |
|-------|--------|-------|
| Release build configuration correct | ⬜ | |
| Debug symbols stripped in release | ⬜ | |
| App Transport Security configured | ⬜ | |
| Info.plist permissions documented | ⬜ | |
| Separate schemes for dev/staging/prod | ⬜ | |
| Bundle IDs per environment | ⬜ | |
| API URLs in config (not hardcoded) | ⬜ | |

### 6.4 Android Build Configuration

| Check | Status | Notes |
|-------|--------|-------|
| Release build type configured | ⬜ | |
| Signing config for release | ⬜ | |
| ProGuard rules complete | ⬜ | |
| Manifest permissions minimized | ⬜ | |
| Build flavors for environments | ⬜ | |
| API URLs in BuildConfig | ⬜ | |

### 6.5 Web Build Configuration

| Check | Status | Notes |
|-------|--------|-------|
| Production build optimized | ⬜ | |
| Source maps disabled in production | ⬜ | |
| Environment variables not exposed to client | ⬜ | |
| Bundle size optimized | ⬜ | |
| Tree shaking enabled | ⬜ | |

---

## 7. PUSH NOTIFICATIONS

| Check | iOS | Android | Web | Backend | Notes |
|-------|-----|---------|-----|---------|-------|
| Push registration flow | ⬜ | ⬜ | ⬜ | ⬜ | |
| Token storage/update | ⬜ | ⬜ | ⬜ | ⬜ | |
| Token invalidation handling | ⬜ | ⬜ | ⬜ | ⬜ | |
| Multi-device token handling | ⬜ | ⬜ | ⬜ | ⬜ | |
| Notification permissions request | ⬜ | ⬜ | ⬜ | N/A | |
| Notification received (foreground) | ⬜ | ⬜ | ⬜ | N/A | |
| Notification received (background) | ⬜ | ⬜ | ⬜ | N/A | |
| Notification tap handling/deep linking | ⬜ | ⬜ | ⬜ | N/A | |
| Silent/data notifications | ⬜ | ⬜ | N/A | ⬜ | |
| Notification categories/actions | ⬜ | ⬜ | N/A | ⬜ | |

---

## 8. THIRD-PARTY INTEGRATIONS

| Service | Implemented | iOS | Android | Web | Backend | Notes |
|---------|-------------|-----|---------|-----|---------|-------|
| Firebase Auth | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | |
| Firebase Cloud Messaging | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | |
| Firebase Analytics | ⬜ | ⬜ | ⬜ | ⬜ | N/A | |
| Firebase Crashlytics | ⬜ | ⬜ | ⬜ | N/A | N/A | |
| AWS S3 | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | |
| AWS Cognito | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | |
| AWS SES/SNS | ⬜ | N/A | N/A | N/A | ⬜ | |
| Stripe | ❌ | ❌ | ❌ | ❌ | ❌ | NOT IMPLEMENTED |
| Google Maps | ❌ | ❌ | ❌ | ❌ | N/A | NOT IMPLEMENTED |
| Apple Sign In | ⬜ | ⬜ | N/A | ⬜ | ⬜ | |
| Google Sign In | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | |
| [Add other services] | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | |

---

## 9. TESTING STATUS

| Test Type | Backend | iOS | Android | Web | Coverage % | Notes |
|-----------|---------|-----|---------|-----|------------|-------|
| Unit tests exist | ⬜ | ⬜ | ⬜ | ⬜ | | |
| Integration tests exist | ⬜ | ⬜ | ⬜ | ⬜ | | |
| E2E tests exist | ⬜ | ⬜ | ⬜ | ⬜ | | |
| API tests (Postman/Insomnia) | ⬜ | N/A | N/A | N/A | | |
| UI tests | N/A | ⬜ | ⬜ | ⬜ | | |
| Test coverage measured | ⬜ | ⬜ | ⬜ | ⬜ | | |
| CI/CD runs tests | ⬜ | ⬜ | ⬜ | ⬜ | | |

---

## 10. API ENDPOINT INVENTORY

> Document all backend endpoints and their status

| Method | Endpoint | Auth Required | Implemented | iOS Uses | Android Uses | Web Uses | Notes |
|--------|----------|---------------|-------------|----------|--------------|----------|-------|
| POST | /auth/register | No | ⬜ | ⬜ | ⬜ | ⬜ | |
| POST | /auth/login | No | ⬜ | ⬜ | ⬜ | ⬜ | |
| POST | /auth/logout | Yes | ⬜ | ⬜ | ⬜ | ⬜ | |
| POST | /auth/refresh | Yes | ⬜ | ⬜ | ⬜ | ⬜ | |
| POST | /auth/forgot-password | No | ⬜ | ⬜ | ⬜ | ⬜ | |
| POST | /auth/reset-password | No | ⬜ | ⬜ | ⬜ | ⬜ | |
| GET | /user/profile | Yes | ⬜ | ⬜ | ⬜ | ⬜ | |
| PUT | /user/profile | Yes | ⬜ | ⬜ | ⬜ | ⬜ | |
| DELETE | /user/account | Yes | ⬜ | ⬜ | ⬜ | ⬜ | |
| | | | ⬜ | ⬜ | ⬜ | ⬜ | |
| | | | ⬜ | ⬜ | ⬜ | ⬜ | |

---

## 11. FINDINGS SUMMARY

### 🔴 Critical Issues (Must Fix Before Production)
| # | Component | Issue | Description | Status |
|---|-----------|-------|-------------|--------|
| 1 | | | | ⬜ |

### 🟠 High Priority Issues
| # | Component | Issue | Description | Status |
|---|-----------|-------|-------------|--------|
| 1 | | | | ⬜ |

### 🟡 Medium Priority Issues
| # | Component | Issue | Description | Status |
|---|-----------|-------|-------------|--------|
| 1 | | | | ⬜ |

### 🟢 Low Priority / Nice to Have
| # | Component | Issue | Description | Status |
|---|-----------|-------|-------------|--------|
| 1 | | | | ⬜ |

### Cross-Platform Discrepancies
| # | Feature | iOS Behavior | Android Behavior | Web Behavior | Severity | Resolution |
|---|---------|--------------|------------------|--------------|----------|------------|
| 1 | | | | | | |

### Missing/Incomplete Flows
| # | Flow | iOS | Android | Web | Backend | Priority | Notes |
|---|------|-----|---------|-----|---------|----------|-------|
| 1 | | | | | | | |

### Database Issues
| # | Table/Field | Issue | Severity | Resolution |
|---|-------------|-------|----------|------------|
| 1 | | | | |

### Security Vulnerabilities
| # | Component | Vulnerability | CVSS/Severity | Remediation | Status |
|---|-----------|---------------|---------------|-------------|--------|
| 1 | | | | | ⬜ |

---

## 12. AUDIT EXECUTION COMMANDS

### Backend Analysis (project-Xtag)
```bash
# Find all routes/endpoints
grep -rn "router\." --include="*.js" --include="*.ts" project-Xtag/
grep -rn "app\.\(get\|post\|put\|patch\|delete\)" --include="*.js" --include="*.ts" project-Xtag/

# Find auth middleware usage
grep -rn "authenticate\|isAuth\|requireAuth\|protect\|verifyToken" --include="*.js" --include="*.ts" project-Xtag/

# Find database queries (check for SQL injection)
grep -rn "\.query\|\.execute\|\.raw\|sequelize\|prisma" --include="*.js" --include="*.ts" project-Xtag/

# Find environment variable usage
grep -rn "process\.env" --include="*.js" --include="*.ts" project-Xtag/

# Find hardcoded secrets (REVIEW MANUALLY)
grep -rn "password\|secret\|key\|token" --include="*.js" --include="*.ts" project-Xtag/ | grep -E "[:=]\s*['\"]"

# Find TODO/FIXME/HACK comments
grep -rnE "(TODO|FIXME|HACK|XXX|TEMP|BUG)" --include="*.js" --include="*.ts" project-Xtag/

# Find console.log statements (should be removed in production)
grep -rn "console\.log" --include="*.js" --include="*.ts" project-Xtag/

# Find all models/tables
find project-Xtag -type f \( -name "*.model.js" -o -name "*.model.ts" -o -name "schema.prisma" \)

# Find all migrations
find project-Xtag -type d -name "migrations"
```

### iOS Analysis (pet-safety-ios)
```bash
# Find API endpoints/URLs
grep -rn "https://\|http://" --include="*.swift" pet-safety-ios/

# Find Keychain usage (GOOD - secure storage)
grep -rn "Keychain\|SecItem\|KeychainWrapper" --include="*.swift" pet-safety-ios/

# Find UserDefaults usage (BAD for sensitive data)
grep -rn "UserDefaults" --include="*.swift" pet-safety-ios/

# Find hardcoded strings that might be secrets
grep -rn "apiKey\|secret\|password\|token" --include="*.swift" pet-safety-ios/

# Find TODO/FIXME
grep -rnE "(TODO|FIXME|HACK|XXX)" --include="*.swift" pet-safety-ios/

# Find print statements (remove in production)
grep -rn "print(" --include="*.swift" pet-safety-ios/

# Find network calls
grep -rn "URLSession\|Alamofire\|URLRequest" --include="*.swift" pet-safety-ios/

# Find info.plist permissions
find pet-safety-ios -name "Info.plist" -exec grep -l "NSCamera\|NSLocation\|NSPhoto\|NSMicrophone" {} \;
```

### Android Analysis (pet-safety-android)
```bash
# Find API endpoints/URLs
grep -rn "https://\|http://" --include="*.kt" --include="*.java" pet-safety-android/

# Find SharedPreferences usage (check what's stored)
grep -rn "SharedPreferences\|getSharedPreferences\|PreferenceManager" --include="*.kt" --include="*.java" pet-safety-android/

# Find EncryptedSharedPreferences (GOOD - secure storage)
grep -rn "EncryptedSharedPreferences" --include="*.kt" --include="*.java" pet-safety-android/

# Find hardcoded strings
grep -rn "apiKey\|secret\|password\|token" --include="*.kt" --include="*.java" pet-safety-android/

# Find TODO/FIXME
grep -rnE "(TODO|FIXME|HACK|XXX)" --include="*.kt" --include="*.java" pet-safety-android/

# Find Log statements (remove in production)
grep -rn "Log\.\|println" --include="*.kt" --include="*.java" pet-safety-android/

# Check AndroidManifest for permissions and backup settings
find pet-safety-android -name "AndroidManifest.xml" -exec cat {} \;

# Find ProGuard rules
find pet-safety-android -name "proguard-rules.pro" -o -name "proguard.cfg"

# Find build.gradle for signing config
find pet-safety-android -name "build.gradle*" -exec grep -l "signingConfigs\|buildTypes" {} \;
```

### Web App Analysis (project-Xtag)
```bash
# Find API calls
grep -rn "fetch\|axios\|http" --include="*.js" --include="*.ts" --include="*.jsx" --include="*.tsx" project-Xtag/

# Find localStorage/sessionStorage usage
grep -rn "localStorage\|sessionStorage" --include="*.js" --include="*.ts" --include="*.jsx" --include="*.tsx" project-Xtag/

# Find environment variable usage (client-side)
grep -rn "NEXT_PUBLIC_\|REACT_APP_\|VITE_" --include="*.js" --include="*.ts" --include="*.jsx" --include="*.tsx" project-Xtag/

# Find TODO/FIXME
grep -rnE "(TODO|FIXME|HACK|XXX)" --include="*.js" --include="*.ts" --include="*.jsx" --include="*.tsx" project-Xtag/

# Find console.log
grep -rn "console\.log" --include="*.js" --include="*.ts" --include="*.jsx" --include="*.tsx" project-Xtag/
```

---

## 13. AUDIT CHECKLIST SUMMARY

### Pre-Production Go/No-Go

| Category | Pass | Fail | Notes |
|----------|------|------|-------|
| Authentication secure | ⬜ | ⬜ | |
| Authorization working | ⬜ | ⬜ | |
| No SQL/NoSQL injection | ⬜ | ⬜ | |
| No XSS vulnerabilities | ⬜ | ⬜ | |
| Secrets not exposed | ⬜ | ⬜ | |
| All critical flows work | ⬜ | ⬜ | |
| Cross-platform parity | ⬜ | ⬜ | |
| Error handling complete | ⬜ | ⬜ | |
| Logging appropriate | ⬜ | ⬜ | |
| Database migrations clean | ⬜ | ⬜ | |
| No TODO/FIXME in critical paths | ⬜ | ⬜ | |

---

## 14. AUDIT LOG

| Date | Auditor | Section | Files Reviewed | Findings |
|------|---------|---------|----------------|----------|
| | | | | |
| | | | | |

---

## Legend

- ✅ Pass / Implemented / Working
- ❌ Fail / Not Implemented / Broken
- ⚠️ Partial / Needs Attention
- ⬜ Not Yet Checked
- N/A Not Applicable
