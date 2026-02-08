# Alert Notification Flow - Implementation Spec (GDPR Compliant)

## Overview

**Task:** Implement production-ready, GDPR-compliant alert notification system for pet tag scans with optional location sharing.

**Flow Summary:**
1. Finder scans pet's QR tag
2. Finder optionally shares their location (three tiers: none / approximate / precise)
3. Backend receives scan + location data (no PII collected)
4. Backend sends FCM push notification to owner with coordinates (if shared)
5. Backend sends email to owner with map link (if location shared)
6. Owner taps notification → opens location in preferred map app

**Repositories Involved:**
- `pet-safety-eu` (Backend - Node.js/Express)
- `pet-safety-ios` (iOS - SwiftUI)
- `pet-safety-android` (Android - Kotlin/Compose)
- `project-tag` (Web - React, for finder's scan page)

---

## GDPR Compliance & Data Minimization

### Finder Data Collection Rules

| Data | Collect? | Lawful Basis | Notes |
|------|----------|--------------|-------|
| **Exact GPS location** | Optional, explicit consent | Consent (Art. 6(1)(a)) | Finder must actively select "Share precise location" |
| **Approximate location** | Optional, explicit consent | Consent (Art. 6(1)(a)) | Fallback tier; ~500m accuracy |
| **IP-derived location** | ❌ No | — | Too inaccurate and legally grey |
| **Phone number** | ❌ No | — | Not necessary; creates liability |
| **Email** | ❌ No | — | Not necessary; creates liability |
| **Name** | ❌ No | — | Not necessary; creates liability |

### Key GDPR Principles Applied

1. **Data Minimization**: Only collect location, and only with explicit consent
2. **Purpose Limitation**: Data used solely for this notification, not marketing
3. **Consent Must Be**: Freely given, specific, informed, unambiguous
4. **No Dark Patterns**: Default is NO sharing; each tier is explicit opt-in
5. **Transparency**: Clear explanation before consent
6. **Retention Limit**: Auto-delete after 90 days

---

## Location Accuracy Tiers

### Tier 1: No Location (Finder Denies All)
- Notification says: "Your pet's tag was scanned"
- No coordinates in FCM/email
- Still valuable - owner knows pet is alive and tag is readable

### Tier 2: Approximate Location (~100-500m accuracy)
- Finder selects "Share approximate area"
- Uses Geolocation API with `enableHighAccuracy: false`
- Coordinates rounded to 3 decimal places (~111m precision)
- Notification says: "Your pet's tag was scanned near this area"
- Map link centers on coordinates with "approximate" indicator

### Tier 3: Precise Location (<50m accuracy)
- Finder explicitly selects "Share exact location"
- Uses Geolocation API with `enableHighAccuracy: true`
- Full precision coordinates
- Notification says: "Your pet's tag was scanned at this location"

---

## Critical Requirements

### Non-Negotiables
- **Production-ready code** - No TODOs, no placeholder implementations, no skipped error handling
- **Full test coverage** - Unit tests, integration tests for all new code
- **GDPR compliant** - No PII collection, explicit consent for location, 90-day retention
- **Security first** - Validate all inputs, sanitize coordinates, rate limit notifications
- **Graceful degradation** - If FCM fails, email must still send; if no location, send scan-only alert
- **Idempotency** - Duplicate scan submissions must not spam owner
- **Audit trail** - Log all notification attempts with success/failure status

### Industry Standards
- FCM: Use HTTP v1 API (not legacy)
- Email: Transactional email service (AWS SES, SendGrid, or similar)
- Coordinates: WGS84 format, validate lat/lng bounds
- Deep links: Universal Links (iOS) + App Links (Android) + fallback URLs
- Rate limiting: Max 5 notifications per pet per hour from same IP

---

## Data Flow Diagram

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────────────────┐
│     FINDER      │     │     BACKEND     │     │           OWNER             │
│  (Web/Scanner)  │     │  (pet-safety-eu)│     │  (iOS/Android/Email)        │
└────────┬────────┘     └────────┬────────┘     └──────────────┬──────────────┘
         │                       │                             │
         │  POST /scans          │                             │
         │  {code, location?}    │                             │
         │──────────────────────>│                             │
         │                       │                             │
         │                       │  Validate scan              │
         │                       │  Check rate limits          │
         │                       │  Get owner FCM tokens       │
         │                       │  Get owner email            │
         │                       │                             │
         │                       │  Send FCM notification      │
         │                       │────────────────────────────>│
         │                       │                             │  Display push
         │                       │  Send email with map link   │  with location
         │                       │────────────────────────────>│
         │                       │                             │
         │  200 OK               │                             │
         │  {scan_id, status}    │                             │
         │<──────────────────────│                             │
         │                       │                             │
         │                       │                             │  Owner taps
         │                       │                             │  notification
         │                       │                             │      │
         │                       │                             │      ▼
         │                       │                             │  Opens in Maps
         │                       │                             │  (Google/Apple/
         │                       │                             │   Waze picker)
```

---

## Consent UI Flow

```
┌─────────────────────────────────────────────────────────────┐
│              CONSENT SCREEN (Web/App)                       │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  🐕 This is Buddy! Help reunite them with their owner.      │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐    │
│  │ 📍 Share your location to help the owner find       │    │
│  │    their pet faster                                 │    │
│  │                                                     │    │
│  │    ◉ Don't share location          [DEFAULT]       │    │
│  │    ○ Share approximate area (~500m)                │    │
│  │    ○ Share exact location                          │    │
│  │                                                     │    │
│  │ Your location is shared only with the pet owner    │    │
│  │ for this notification. We do not store or track    │    │
│  │ your location beyond 90 days. [Privacy Policy]     │    │
│  └─────────────────────────────────────────────────────┘    │
│                                                             │
│              [ Notify Owner ]                               │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## Backend Implementation (pet-safety-eu)

### New/Modified Files

```
src/
├── services/
│   ├── notification.service.ts    # NEW - Orchestrates FCM + Email
│   ├── fcm.service.ts             # NEW - Firebase Cloud Messaging
│   └── email.service.ts           # MODIFY - Add location templates
├── controllers/
│   └── scan.controller.ts         # MODIFY - Add location handling
├── routes/
│   └── scan.routes.ts             # MODIFY - Update endpoint
├── validators/
│   └── scan.validator.ts          # MODIFY - Add coordinate validation
├── templates/
│   └── emails/
│       ├── pet-scanned-precise.html    # NEW
│       ├── pet-scanned-approximate.html # NEW
│       └── pet-scanned-no-location.html # NEW
├── jobs/
│   └── data-retention.job.ts      # NEW - GDPR 90-day cleanup
└── utils/
    ├── coordinates.ts             # NEW - Geo utilities
    └── map-links.ts               # NEW - Generate map URLs
```

### Database Schema

```sql
-- Scans table - GDPR compliant (NO PII)
CREATE TABLE IF NOT EXISTS scans (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    qr_code VARCHAR(20) NOT NULL,
    pet_id UUID REFERENCES pets(id),
    
    -- Location (optional, consent-based only)
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    location_accuracy_meters DECIMAL(10, 2),
    location_is_approximate BOOLEAN DEFAULT false,
    location_consent_type VARCHAR(20),  -- 'approximate', 'precise', NULL
    
    -- Rate limiting (hashed, not PII)
    ip_hash VARCHAR(64),
    
    -- Metadata
    created_at TIMESTAMPTZ DEFAULT NOW()
    
    -- INTENTIONALLY OMITTED: finder_name, finder_phone, finder_email, finder_message
);

CREATE INDEX idx_scans_pet_id ON scans(pet_id);
CREATE INDEX idx_scans_created_at ON scans(created_at);

-- Add FCM tokens to users table
ALTER TABLE users ADD COLUMN IF NOT EXISTS fcm_tokens JSONB DEFAULT '[]';
-- Structure: [{"token": "xxx", "platform": "ios|android", "updated_at": "..."}]

-- Notification log table (for debugging/audit)
CREATE TABLE IF NOT EXISTS notification_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    scan_id UUID REFERENCES scans(id),
    user_id UUID REFERENCES users(id),
    type VARCHAR(20) NOT NULL,        -- 'fcm' | 'email'
    status VARCHAR(20) NOT NULL,      -- 'sent' | 'failed' | 'skipped'
    error_message TEXT,
    metadata JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_notification_logs_scan ON notification_logs(scan_id);
CREATE INDEX idx_notification_logs_created ON notification_logs(created_at);
```

### API Endpoint Specification

#### POST /api/v1/scans

**Request:**
```json
{
  "code": "ABC123XYZ",
  "location": {
    "latitude": 47.497,
    "longitude": 19.040,
    "accuracy_meters": 150,
    "is_approximate": true,
    "consent_type": "approximate"
  }
}
```

**Validation Rules:**
- `code`: Required, string, 6-20 chars, alphanumeric
- `location`: Optional (entire object)
- `location.latitude`: Required if location present, number, -90 to 90
- `location.longitude`: Required if location present, number, -180 to 180
- `location.accuracy_meters`: Required if location present, number, 0 to 10000
- `location.is_approximate`: Required if location present, boolean
- `location.consent_type`: Required if location present, enum: `"approximate"` | `"precise"`

**API must reject these fields if present (GDPR):**
- `finder_name`
- `finder_phone`
- `finder_email`
- `finder_message`

**Response (200):**
```json
{
  "scan_id": "uuid",
  "pet": {
    "name": "Buddy",
    "species": "dog",
    "image_url": "https://..."
  },
  "is_missing": true,
  "owner_notified": true
}
```

**Response (404):**
```json
{
  "error": "TAG_NOT_FOUND",
  "message": "This tag is not registered"
}
```

**Response (429):**
```json
{
  "error": "RATE_LIMITED",
  "message": "Too many scans. Please try again later.",
  "retry_after": 300
}
```

### Request Validation

```typescript
// src/validators/scan.validator.ts

import { z } from 'zod';

const locationSchema = z.object({
  latitude: z.number().min(-90).max(90),
  longitude: z.number().min(-180).max(180),
  accuracy_meters: z.number().min(0).max(10000),
  is_approximate: z.boolean(),
  consent_type: z.enum(['approximate', 'precise']),
}).refine(
  (data) => {
    // Ensure consent_type matches is_approximate flag
    if (data.consent_type === 'approximate') return data.is_approximate === true;
    if (data.consent_type === 'precise') return data.is_approximate === false;
    return true;
  },
  { message: 'consent_type and is_approximate must be consistent' }
);

export const scanSchema = z.object({
  code: z.string().min(6).max(20).regex(/^[A-Za-z0-9]+$/),
  location: locationSchema.optional().nullable(),
}).strict(); // Reject any fields not defined (blocks PII attempts)
```

### Rate Limiting Middleware

```typescript
// src/middleware/scan-rate-limit.ts

import { Redis } from 'ioredis';
import { Request, Response, NextFunction } from 'express';
import crypto from 'crypto';

const WINDOW_SECONDS = 3600; // 1 hour
const MAX_SCANS_PER_PET = 5;

export function scanRateLimiter(redis: Redis) {
  return async (req: Request, res: Response, next: NextFunction) => {
    const { code } = req.body;
    const ip = req.ip || req.connection.remoteAddress || 'unknown';
    
    // Hash IP for privacy (not stored as PII)
    const ipHash = crypto.createHash('sha256').update(ip).digest('hex').substring(0, 16);
    
    const key = `scan_limit:${code}:${ipHash}`;
    
    const count = await redis.incr(key);
    
    if (count === 1) {
      await redis.expire(key, WINDOW_SECONDS);
    }
    
    if (count > MAX_SCANS_PER_PET) {
      const ttl = await redis.ttl(key);
      return res.status(429).json({
        error: 'RATE_LIMITED',
        message: 'Too many scans for this tag. Please try again later.',
        retry_after: ttl,
      });
    }
    
    // Store hash for audit (not PII)
    req.body._ipHash = ipHash;
    
    next();
  };
}
```

### FCM Service

```typescript
// src/services/fcm.service.ts

import * as admin from 'firebase-admin';

interface LocationPayload {
  latitude: number;
  longitude: number;
  accuracy_meters?: number;
  is_approximate: boolean;
}

interface ScanNotificationPayload {
  scanId: string;
  petId: string;
  petName: string;
  location?: LocationPayload;
}

export class FCMService {
  private app: admin.app.App;

  constructor() {
    this.app = admin.initializeApp({
      credential: admin.credential.cert({
        projectId: process.env.FIREBASE_PROJECT_ID,
        clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
        privateKey: process.env.FIREBASE_PRIVATE_KEY?.replace(/\\n/g, '\n'),
      }),
    });
  }

  async sendScanNotification(
    tokens: string[],
    payload: ScanNotificationPayload
  ): Promise<{ success: string[]; failed: string[] }> {
    if (tokens.length === 0) {
      return { success: [], failed: [] };
    }

    const { petName, location } = payload;
    const { title, body } = this.buildNotificationContent(petName, location);

    // Build data payload for app handling
    const data: Record<string, string> = {
      type: 'PET_SCANNED',
      scan_id: payload.scanId,
      pet_id: payload.petId,
      click_action: 'OPEN_SCAN_DETAILS',
    };

    if (location) {
      data.latitude = location.latitude.toString();
      data.longitude = location.longitude.toString();
      data.location_type = location.is_approximate ? 'approximate' : 'precise';
    } else {
      data.location_type = 'none';
    }

    const message: admin.messaging.MulticastMessage = {
      tokens,
      notification: { title, body },
      data,
      android: {
        priority: 'high',
        notification: {
          channelId: 'pet_alerts',
          priority: 'high',
          defaultSound: true,
          defaultVibrateTimings: true,
        },
      },
      apns: {
        payload: {
          aps: {
            alert: { title, body },
            sound: 'default',
            badge: 1,
            'mutable-content': 1,
          },
        },
        headers: {
          'apns-priority': '10',
          'apns-push-type': 'alert',
        },
      },
    };

    const response = await admin.messaging().sendEachForMulticast(message);

    const success: string[] = [];
    const failed: string[] = [];

    response.responses.forEach((resp, idx) => {
      if (resp.success) {
        success.push(tokens[idx]);
      } else {
        failed.push(tokens[idx]);
        console.error(`FCM send failed for token ${idx}:`, resp.error);
      }
    });

    return { success, failed };
  }

  private buildNotificationContent(
    petName: string,
    location?: LocationPayload
  ): { title: string; body: string } {
    if (!location) {
      return {
        title: `🔔 ${petName}'s tag was scanned!`,
        body: `Someone found your pet and scanned their tag. They chose not to share their location.`,
      };
    }

    if (location.is_approximate) {
      return {
        title: `📍 ${petName}'s tag was scanned nearby!`,
        body: `Someone scanned your pet's tag and shared their approximate area (~500m). Tap to see on map.`,
      };
    }

    return {
      title: `📍 ${petName}'s tag was scanned with exact location!`,
      body: `Great news! Someone shared their precise location. Tap to see on map.`,
    };
  }

  async removeInvalidTokens(userId: string, invalidTokens: string[]): Promise<void> {
    // Implementation: Remove tokens from users.fcm_tokens JSONB array
  }
}
```

### Map Link Generation

```typescript
// src/utils/map-links.ts

interface Coordinates {
  latitude: number;
  longitude: number;
}

interface MapLinks {
  universal: string;
  google: string;
  apple: string;
  waze: string;
  web: string;
}

export function generateMapLinks(coords: Coordinates, label?: string): MapLinks {
  const { latitude, longitude } = coords;
  const encodedLabel = encodeURIComponent(label || 'Pet Location');

  return {
    universal: `geo:${latitude},${longitude}?q=${latitude},${longitude}(${encodedLabel})`,
    google: `https://www.google.com/maps/search/?api=1&query=${latitude},${longitude}`,
    apple: `https://maps.apple.com/?ll=${latitude},${longitude}&q=${encodedLabel}`,
    waze: `https://waze.com/ul?ll=${latitude},${longitude}&navigate=yes`,
    web: `https://www.google.com/maps?q=${latitude},${longitude}`,
  };
}

export function generateMapLinksHTML(
  coords: Coordinates,
  petName: string,
  isApproximate: boolean
): string {
  const links = generateMapLinks(coords, `${petName} Location`);
  
  return `
    <div style="margin: 20px 0;">
      <p style="font-size: 16px; margin-bottom: 15px;">
        <strong>📍 Location:</strong> ${coords.latitude.toFixed(isApproximate ? 3 : 6)}, ${coords.longitude.toFixed(isApproximate ? 3 : 6)}
        ${isApproximate ? '<span style="color: #e65100;"> (approximate)</span>' : ''}
      </p>
      <table role="presentation" cellspacing="0" cellpadding="0">
        <tr>
          <td style="padding-right: 10px; padding-bottom: 10px;">
            <a href="${links.google}" 
               style="background-color: #4285F4; color: white; padding: 12px 24px; 
                      text-decoration: none; border-radius: 6px; display: inline-block;
                      font-weight: bold;">
              Open in Google Maps
            </a>
          </td>
          <td style="padding-right: 10px; padding-bottom: 10px;">
            <a href="${links.apple}" 
               style="background-color: #000000; color: white; padding: 12px 24px; 
                      text-decoration: none; border-radius: 6px; display: inline-block;
                      font-weight: bold;">
              Open in Apple Maps
            </a>
          </td>
          <td style="padding-bottom: 10px;">
            <a href="${links.waze}" 
               style="background-color: #33CCFF; color: white; padding: 12px 24px; 
                      text-decoration: none; border-radius: 6px; display: inline-block;
                      font-weight: bold;">
              Open in Waze
            </a>
          </td>
        </tr>
      </table>
    </div>
  `;
}
```

### Notification Service (Orchestrator)

```typescript
// src/services/notification.service.ts

import { FCMService } from './fcm.service';
import { EmailService } from './email.service';
import { generateMapLinksHTML } from '../utils/map-links';
import { NotificationLog, User, Pet, Scan } from '../models';

interface NotifyOwnerParams {
  scan: Scan;
  pet: Pet;
  owner: User;
}

export class NotificationService {
  constructor(
    private fcmService: FCMService,
    private emailService: EmailService
  ) {}

  async notifyOwnerOfScan(params: NotifyOwnerParams): Promise<{
    fcmSent: boolean;
    emailSent: boolean;
  }> {
    const { scan, pet, owner } = params;
    const results = { fcmSent: false, emailSent: false };

    const hasLocation = scan.latitude !== null && scan.longitude !== null;
    const location = hasLocation ? {
      latitude: scan.latitude!,
      longitude: scan.longitude!,
      accuracy_meters: scan.location_accuracy_meters,
      is_approximate: scan.location_is_approximate,
    } : undefined;

    // Send both notifications concurrently, handle failures independently
    const [fcmResult, emailResult] = await Promise.allSettled([
      this.sendFCMNotification(scan, pet, owner, location),
      this.sendEmailNotification(scan, pet, owner, location),
    ]);

    if (fcmResult.status === 'fulfilled') {
      results.fcmSent = fcmResult.value;
    } else {
      await this.logNotification(scan.id, owner.id, 'fcm', 'failed', fcmResult.reason?.message);
    }

    if (emailResult.status === 'fulfilled') {
      results.emailSent = emailResult.value;
    } else {
      await this.logNotification(scan.id, owner.id, 'email', 'failed', emailResult.reason?.message);
    }

    return results;
  }

  private async sendFCMNotification(
    scan: Scan,
    pet: Pet,
    owner: User,
    location?: { latitude: number; longitude: number; accuracy_meters?: number; is_approximate: boolean }
  ): Promise<boolean> {
    const tokens = owner.fcm_tokens?.map(t => t.token) || [];
    
    if (tokens.length === 0) {
      await this.logNotification(scan.id, owner.id, 'fcm', 'skipped', 'No FCM tokens');
      return false;
    }

    const result = await this.fcmService.sendScanNotification(tokens, {
      scanId: scan.id,
      petId: pet.id,
      petName: pet.name,
      location,
    });

    if (result.failed.length > 0) {
      await this.fcmService.removeInvalidTokens(owner.id, result.failed);
    }

    const success = result.success.length > 0;
    await this.logNotification(
      scan.id,
      owner.id,
      'fcm',
      success ? 'sent' : 'failed',
      success ? null : 'All tokens failed',
      { sent: result.success.length, failed: result.failed.length }
    );

    return success;
  }

  private async sendEmailNotification(
    scan: Scan,
    pet: Pet,
    owner: User,
    location?: { latitude: number; longitude: number; accuracy_meters?: number; is_approximate: boolean }
  ): Promise<boolean> {
    if (!owner.email) {
      await this.logNotification(scan.id, owner.id, 'email', 'skipped', 'No email address');
      return false;
    }

    if (!owner.notification_preferences?.email_on_scan) {
      await this.logNotification(scan.id, owner.id, 'email', 'skipped', 'Email notifications disabled');
      return false;
    }

    // Determine template based on location tier
    let template: string;
    let subject: string;

    if (!location) {
      template = 'pet-scanned-no-location';
      subject = `🔔 ${pet.name}'s tag was scanned!`;
    } else if (location.is_approximate) {
      template = 'pet-scanned-approximate';
      subject = `📍 ${pet.name}'s tag was scanned nearby!`;
    } else {
      template = 'pet-scanned-precise';
      subject = `📍 ${pet.name}'s tag was scanned with exact location!`;
    }

    const templateData = {
      petName: pet.name,
      petImageUrl: pet.profile_image,
      hasLocation: !!location,
      isApproximate: location?.is_approximate ?? false,
      mapLinksHTML: location 
        ? generateMapLinksHTML(
            { latitude: location.latitude, longitude: location.longitude },
            pet.name,
            location.is_approximate
          )
        : '',
      accuracyMeters: location?.accuracy_meters?.toFixed(0) || 'Unknown',
      scanTime: new Date(scan.created_at).toLocaleString(),
      isMissing: pet.is_missing,
      appDeepLink: `petsafety://scan/${scan.id}`,
      settingsUrl: `${process.env.WEB_URL}/settings/notifications`,
      privacyUrl: `${process.env.WEB_URL}/privacy`,
      logoUrl: `${process.env.CDN_URL}/logo.png`,
      year: new Date().getFullYear(),
    };

    await this.emailService.sendTemplate(owner.email, subject, template, templateData);
    await this.logNotification(scan.id, owner.id, 'email', 'sent');
    return true;
  }

  private async logNotification(
    scanId: string,
    userId: string,
    type: 'fcm' | 'email',
    status: 'sent' | 'failed' | 'skipped',
    errorMessage?: string | null,
    metadata?: Record<string, any>
  ): Promise<void> {
    await NotificationLog.create({
      scan_id: scanId,
      user_id: userId,
      type,
      status,
      error_message: errorMessage,
      metadata,
    });
  }
}
```

### Email Templates

#### Precise Location Email
```html
<!-- src/templates/emails/pet-scanned-precise.html -->
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>{{petName}} was scanned!</title>
</head>
<body style="font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; 
             line-height: 1.6; color: #333; max-width: 600px; margin: 0 auto; padding: 20px;">
  
  <div style="text-align: center; margin-bottom: 30px;">
    <img src="{{logoUrl}}" alt="Pet Safety" style="height: 50px;">
  </div>

  <div style="background-color: #e8f5e9; border-radius: 12px; padding: 30px; margin-bottom: 20px;">
    <h1 style="color: #2e7d32; margin-top: 0;">
      📍 {{petName}}'s tag was scanned with exact location!
    </h1>
    
    <p style="font-size: 18px;">
      Great news! Someone scanned {{petName}}'s tag and shared their <strong>precise location</strong>.
    </p>

    {{#if petImageUrl}}
    <img src="{{petImageUrl}}" alt="{{petName}}" 
         style="width: 150px; height: 150px; border-radius: 75px; object-fit: cover; 
                margin: 20px 0; border: 4px solid #fff; box-shadow: 0 2px 10px rgba(0,0,0,0.1);">
    {{/if}}
  </div>

  <div style="background-color: #e8f5e9; border-radius: 12px; padding: 20px; margin-bottom: 20px; border-left: 4px solid #4caf50;">
    <h2 style="margin-top: 0; color: #2e7d32;">📍 Exact Location</h2>
    {{{mapLinksHTML}}}
    <p style="font-size: 13px; color: #666; margin-bottom: 0;">
      Location accuracy: ±{{accuracyMeters}}m
      <br>
      Time: {{scanTime}}
    </p>
  </div>

  {{#if isMissing}}
  <div style="background-color: #fff3e0; border-radius: 12px; padding: 20px; margin-bottom: 20px;">
    <h2 style="margin-top: 0; color: #ef6c00;">⚠️ {{petName}} is marked as missing</h2>
    <p>This could be the moment you've been waiting for! Act quickly.</p>
    <a href="{{appDeepLink}}" 
       style="background-color: #ef6c00; color: white; padding: 15px 30px; 
              text-decoration: none; border-radius: 8px; display: inline-block;
              font-weight: bold; font-size: 16px;">
      Open in App
    </a>
  </div>
  {{/if}}

  <div style="margin-top: 30px; padding-top: 20px; border-top: 1px solid #eee; 
              text-align: center; color: #666; font-size: 14px;">
    <p>
      <a href="{{settingsUrl}}" style="color: #666;">Manage notification preferences</a>
    </p>
    <p style="margin-top: 20px;">
      © {{year}} Pet Safety • <a href="{{privacyUrl}}" style="color: #666;">Privacy</a>
    </p>
  </div>

</body>
</html>
```

#### Approximate Location Email
```html
<!-- src/templates/emails/pet-scanned-approximate.html -->
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>{{petName}} was scanned!</title>
</head>
<body style="font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; 
             line-height: 1.6; color: #333; max-width: 600px; margin: 0 auto; padding: 20px;">
  
  <div style="text-align: center; margin-bottom: 30px;">
    <img src="{{logoUrl}}" alt="Pet Safety" style="height: 50px;">
  </div>

  <div style="background-color: #fff3e0; border-radius: 12px; padding: 30px; margin-bottom: 20px;">
    <h1 style="color: #e65100; margin-top: 0;">
      📍 {{petName}}'s tag was scanned nearby!
    </h1>
    
    <p style="font-size: 18px;">
      Someone scanned {{petName}}'s tag and shared their <strong>approximate area</strong>.
    </p>

    {{#if petImageUrl}}
    <img src="{{petImageUrl}}" alt="{{petName}}" 
         style="width: 150px; height: 150px; border-radius: 75px; object-fit: cover; 
                margin: 20px 0; border: 4px solid #fff; box-shadow: 0 2px 10px rgba(0,0,0,0.1);">
    {{/if}}
  </div>

  <div style="background-color: #fff3e0; border-radius: 12px; padding: 20px; margin-bottom: 20px; border-left: 4px solid #ff9800;">
    <h2 style="margin-top: 0; color: #e65100;">📍 Approximate Location</h2>
    
    <p style="background: #fff; padding: 12px; border-radius: 6px; margin-bottom: 15px;">
      ⚠️ <strong>Note:</strong> The finder shared their approximate area only (~500m accuracy).
      The map shows the general area - please search the surrounding location.
    </p>
    
    {{{mapLinksHTML}}}
    
    <p style="font-size: 13px; color: #666; margin-bottom: 0;">
      Time: {{scanTime}}
    </p>
  </div>

  {{#if isMissing}}
  <div style="background-color: #ffebee; border-radius: 12px; padding: 20px; margin-bottom: 20px;">
    <h2 style="margin-top: 0; color: #c62828;">⚠️ {{petName}} is marked as missing</h2>
    <p>This could be a lead! Head to the general area and search around.</p>
    <a href="{{appDeepLink}}" 
       style="background-color: #c62828; color: white; padding: 15px 30px; 
              text-decoration: none; border-radius: 8px; display: inline-block;
              font-weight: bold; font-size: 16px;">
      Open in App
    </a>
  </div>
  {{/if}}

  <div style="margin-top: 30px; padding-top: 20px; border-top: 1px solid #eee; 
              text-align: center; color: #666; font-size: 14px;">
    <p>
      <a href="{{settingsUrl}}" style="color: #666;">Manage notification preferences</a>
    </p>
    <p style="margin-top: 20px;">
      © {{year}} Pet Safety • <a href="{{privacyUrl}}" style="color: #666;">Privacy</a>
    </p>
  </div>

</body>
</html>
```

#### No Location Email
```html
<!-- src/templates/emails/pet-scanned-no-location.html -->
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>{{petName}} was scanned!</title>
</head>
<body style="font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; 
             line-height: 1.6; color: #333; max-width: 600px; margin: 0 auto; padding: 20px;">
  
  <div style="text-align: center; margin-bottom: 30px;">
    <img src="{{logoUrl}}" alt="Pet Safety" style="height: 50px;">
  </div>

  <div style="background-color: #f5f5f5; border-radius: 12px; padding: 30px; margin-bottom: 20px;">
    <h1 style="color: #424242; margin-top: 0;">
      🔔 {{petName}}'s tag was scanned!
    </h1>
    
    <p style="font-size: 18px;">
      Someone found your pet and scanned their tag. They chose not to share their location.
    </p>

    {{#if petImageUrl}}
    <img src="{{petImageUrl}}" alt="{{petName}}" 
         style="width: 150px; height: 150px; border-radius: 75px; object-fit: cover; 
                margin: 20px 0; border: 4px solid #fff; box-shadow: 0 2px 10px rgba(0,0,0,0.1);">
    {{/if}}
  </div>

  <div style="background-color: #e3f2fd; border-radius: 12px; padding: 20px; margin-bottom: 20px;">
    <h2 style="margin-top: 0; color: #1565c0;">What this means</h2>
    <p style="margin-bottom: 0;">
      Your pet's tag was scanned at <strong>{{scanTime}}</strong>. While the finder 
      chose not to share their location, this is still a good sign - it means your 
      pet's tag is readable and someone cared enough to scan it.
    </p>
  </div>

  {{#if isMissing}}
  <div style="background-color: #fff3e0; border-radius: 12px; padding: 20px; margin-bottom: 20px;">
    <h2 style="margin-top: 0; color: #ef6c00;">⚠️ {{petName}} is marked as missing</h2>
    <p>Check common areas where your pet might be found.</p>
    <a href="{{appDeepLink}}" 
       style="background-color: #ef6c00; color: white; padding: 15px 30px; 
              text-decoration: none; border-radius: 8px; display: inline-block;
              font-weight: bold; font-size: 16px;">
      Open in App
    </a>
  </div>
  {{/if}}

  <div style="margin-top: 30px; padding-top: 20px; border-top: 1px solid #eee; 
              text-align: center; color: #666; font-size: 14px;">
    <p>
      <a href="{{settingsUrl}}" style="color: #666;">Manage notification preferences</a>
    </p>
    <p style="margin-top: 20px;">
      © {{year}} Pet Safety • <a href="{{privacyUrl}}" style="color: #666;">Privacy</a>
    </p>
  </div>

</body>
</html>
```

### Data Retention Job (GDPR)

```typescript
// src/jobs/data-retention.job.ts

import { db } from '../database';

const RETENTION_DAYS = 90;

export async function runDataRetentionCleanup(): Promise<void> {
  const cutoffDate = new Date();
  cutoffDate.setDate(cutoffDate.getDate() - RETENTION_DAYS);

  // Delete old scans
  const scansResult = await db.query(`
    DELETE FROM scans 
    WHERE created_at < $1
    RETURNING id
  `, [cutoffDate]);

  // Delete old notification logs
  const logsResult = await db.query(`
    DELETE FROM notification_logs
    WHERE created_at < $1
    RETURNING id
  `, [cutoffDate]);

  console.log(`Data retention cleanup completed:
    - Deleted ${scansResult.rowCount} scans
    - Deleted ${logsResult.rowCount} notification logs
    - Cutoff date: ${cutoffDate.toISOString()}`);
}

// Schedule with cron: Run daily at 3am
// 0 3 * * * node -e "require('./jobs/data-retention.job').runDataRetentionCleanup()"
```

---

## iOS Implementation (pet-safety-ios)

### New/Modified Files

```
PetSafety/
├── Services/
│   ├── FCMService.swift           # NEW - Firebase messaging setup
│   └── NotificationHandler.swift  # NEW - Handle incoming notifications
├── Views/
│   └── MapPicker/
│       └── MapAppPickerView.swift # NEW - Choose map app sheet
├── Models/
│   └── ScanNotification.swift     # NEW - Notification data model
└── AppDelegate.swift              # MODIFY - FCM setup
```

### AppDelegate FCM Setup

```swift
// AppDelegate.swift

import UIKit
import FirebaseCore
import FirebaseMessaging
import UserNotifications

class AppDelegate: NSObject, UIApplicationDelegate, MessagingDelegate, UNUserNotificationCenterDelegate {
    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        FirebaseApp.configure()
        
        Messaging.messaging().delegate = self
        UNUserNotificationCenter.current().delegate = self
        
        requestNotificationPermission()
        
        return true
    }
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
            if granted {
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
        }
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
    }
    
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let token = fcmToken else { return }
        Task {
            await FCMService.shared.registerToken(token)
        }
    }
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .badge])
    }
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        NotificationHandler.shared.handleNotificationTap(userInfo: userInfo)
        completionHandler()
    }
}
```

### FCM Service

```swift
// Services/FCMService.swift

import Foundation

actor FCMService {
    static let shared = FCMService()
    
    private let apiClient: APIClient
    
    init(apiClient: APIClient = .shared) {
        self.apiClient = apiClient
    }
    
    func registerToken(_ token: String) async {
        do {
            try await apiClient.post(
                endpoint: "/users/me/fcm-tokens",
                body: ["token": token, "platform": "ios"]
            )
        } catch {
            print("Failed to register FCM token: \(error)")
        }
    }
}
```

### Notification Handler

```swift
// Services/NotificationHandler.swift

import Foundation
import SwiftUI

class NotificationHandler: ObservableObject {
    static let shared = NotificationHandler()
    
    @Published var pendingScanNotification: ScanNotificationData?
    @Published var showMapPicker = false
    
    func handleNotificationTap(userInfo: [AnyHashable: Any]) {
        guard let type = userInfo["type"] as? String, type == "PET_SCANNED" else { return }
        
        let scanId = userInfo["scan_id"] as? String ?? ""
        let petId = userInfo["pet_id"] as? String ?? ""
        let locationType = userInfo["location_type"] as? String ?? "none"
        
        var location: LocationData?
        if locationType != "none",
           let latString = userInfo["latitude"] as? String,
           let lonString = userInfo["longitude"] as? String,
           let lat = Double(latString),
           let lon = Double(lonString) {
            location = LocationData(
                latitude: lat,
                longitude: lon,
                isApproximate: locationType == "approximate"
            )
        }
        
        DispatchQueue.main.async {
            self.pendingScanNotification = ScanNotificationData(
                scanId: scanId,
                petId: petId,
                location: location
            )
            
            if location != nil {
                self.showMapPicker = true
            }
        }
    }
}

struct ScanNotificationData: Identifiable {
    let id = UUID()
    let scanId: String
    let petId: String
    let location: LocationData?
}

struct LocationData {
    let latitude: Double
    let longitude: Double
    let isApproximate: Bool
}
```

### Map App Picker

```swift
// Views/MapPicker/MapAppPickerView.swift

import SwiftUI

struct MapAppPickerView: View {
    let location: LocationData
    let petName: String
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                if location.isApproximate {
                    Section {
                        Label {
                            Text("This is an approximate location (~500m). Search the surrounding area.")
                                .font(.callout)
                                .foregroundStyle(.orange)
                        } icon: {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.orange)
                        }
                    }
                }
                
                Section {
                    Text("\(location.latitude, specifier: "%.6f"), \(location.longitude, specifier: "%.6f")")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Section("Open in") {
                    Button(action: openAppleMaps) {
                        Label("Apple Maps", systemImage: "map.fill")
                    }
                    
                    Button(action: openGoogleMaps) {
                        Label("Google Maps", systemImage: "globe")
                    }
                    
                    Button(action: openWaze) {
                        Label("Waze", systemImage: "car.fill")
                    }
                }
            }
            .navigationTitle("📍 \(petName) Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
    
    private func openAppleMaps() {
        let label = petName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "Pet"
        let urlString = "https://maps.apple.com/?ll=\(location.latitude),\(location.longitude)&q=\(label)%20Location"
        if let url = URL(string: urlString) {
            UIApplication.shared.open(url)
        }
        dismiss()
    }
    
    private func openGoogleMaps() {
        let appURL = "comgooglemaps://?q=\(location.latitude),\(location.longitude)"
        let webURL = "https://www.google.com/maps/search/?api=1&query=\(location.latitude),\(location.longitude)"
        
        if let url = URL(string: appURL), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        } else if let url = URL(string: webURL) {
            UIApplication.shared.open(url)
        }
        dismiss()
    }
    
    private func openWaze() {
        let urlString = "https://waze.com/ul?ll=\(location.latitude),\(location.longitude)&navigate=yes"
        if let url = URL(string: urlString) {
            UIApplication.shared.open(url)
        }
        dismiss()
    }
}
```

### Info.plist Additions

```xml
<key>LSApplicationQueriesSchemes</key>
<array>
    <string>comgooglemaps</string>
    <string>waze</string>
</array>

<key>FirebaseAppDelegateProxyEnabled</key>
<false/>
```

---

## Android Implementation (pet-safety-android)

### New/Modified Files

```
app/src/main/java/com/petsafety/app/
├── di/
│   └── FirebaseModule.kt
├── data/
│   └── repository/
│       └── FCMTokenRepository.kt
├── services/
│   └── PetSafetyMessagingService.kt
├── ui/
│   └── mapPicker/
│       └── MapPickerBottomSheet.kt
└── util/
    └── MapIntentBuilder.kt
```

### FCM Messaging Service

```kotlin
// services/PetSafetyMessagingService.kt

package com.petsafety.app.services

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import androidx.core.app.NotificationCompat
import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage
import com.petsafety.app.R
import com.petsafety.app.ui.MainActivity
import com.petsafety.app.util.MapIntentBuilder
import dagger.hilt.android.AndroidEntryPoint
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import javax.inject.Inject

@AndroidEntryPoint
class PetSafetyMessagingService : FirebaseMessagingService() {

    @Inject
    lateinit var fcmTokenRepository: FCMTokenRepository

    companion object {
        const val CHANNEL_ID = "pet_alerts"
        const val CHANNEL_NAME = "Pet Alerts"
    }

    override fun onNewToken(token: String) {
        super.onNewToken(token)
        CoroutineScope(Dispatchers.IO).launch {
            fcmTokenRepository.registerToken(token)
        }
    }

    override fun onMessageReceived(message: RemoteMessage) {
        super.onMessageReceived(message)
        
        val data = message.data
        if (data["type"] == "PET_SCANNED") {
            handleScanNotification(message, data)
        }
    }

    private fun handleScanNotification(message: RemoteMessage, data: Map<String, String>) {
        val scanId = data["scan_id"] ?: return
        val petId = data["pet_id"] ?: return
        val locationType = data["location_type"] ?: "none"
        val latitude = data["latitude"]?.toDoubleOrNull()
        val longitude = data["longitude"]?.toDoubleOrNull()

        createNotificationChannel()

        val tapIntent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            putExtra("scan_id", scanId)
            putExtra("pet_id", petId)
            putExtra("location_type", locationType)
            if (latitude != null && longitude != null) {
                putExtra("latitude", latitude)
                putExtra("longitude", longitude)
            }
        }

        val tapPendingIntent = PendingIntent.getActivity(
            this,
            scanId.hashCode(),
            tapIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val notificationBuilder = NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_notification)
            .setContentTitle(message.notification?.title ?: "Pet Scanned")
            .setContentText(message.notification?.body ?: "Your pet's tag was scanned")
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setAutoCancel(true)
            .setContentIntent(tapPendingIntent)

        // Add "Open Maps" action if location available
        if (locationType != "none" && latitude != null && longitude != null) {
            val mapsIntent = MapIntentBuilder.buildChooserIntent(
                context = this,
                latitude = latitude,
                longitude = longitude,
                label = "Pet Location"
            )
            val mapsPendingIntent = PendingIntent.getActivity(
                this,
                (scanId + "_maps").hashCode(),
                mapsIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            notificationBuilder.addAction(
                R.drawable.ic_map,
                "Open in Maps",
                mapsPendingIntent
            )
        }

        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        notificationManager.notify(scanId.hashCode(), notificationBuilder.build())
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                CHANNEL_NAME,
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Notifications when your pet's tag is scanned"
                enableVibration(true)
            }
            val notificationManager = getSystemService(NotificationManager::class.java)
            notificationManager.createNotificationChannel(channel)
        }
    }
}
```

### Map Intent Builder

```kotlin
// util/MapIntentBuilder.kt

package com.petsafety.app.util

import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri

object MapIntentBuilder {

    data class MapApp(
        val name: String,
        val packageName: String?,
        val buildUri: (Double, Double, String) -> Uri
    )

    private val mapApps = listOf(
        MapApp(
            name = "Google Maps",
            packageName = "com.google.android.apps.maps",
            buildUri = { lat, lon, label ->
                Uri.parse("geo:$lat,$lon?q=$lat,$lon(${Uri.encode(label)})")
            }
        ),
        MapApp(
            name = "Waze",
            packageName = "com.waze",
            buildUri = { lat, lon, _ ->
                Uri.parse("https://waze.com/ul?ll=$lat,$lon&navigate=yes")
            }
        ),
        MapApp(
            name = "Maps (Default)",
            packageName = null,
            buildUri = { lat, lon, label ->
                Uri.parse("geo:$lat,$lon?q=$lat,$lon(${Uri.encode(label)})")
            }
        )
    )

    fun getAvailableMapApps(context: Context): List<MapApp> {
        return mapApps.filter { app ->
            app.packageName == null || isAppInstalled(context, app.packageName)
        }
    }

    fun buildIntent(mapApp: MapApp, latitude: Double, longitude: Double, label: String): Intent {
        val uri = mapApp.buildUri(latitude, longitude, label)
        return Intent(Intent.ACTION_VIEW, uri).apply {
            mapApp.packageName?.let { setPackage(it) }
        }
    }

    fun buildChooserIntent(context: Context, latitude: Double, longitude: Double, label: String): Intent {
        val geoUri = Uri.parse("geo:$latitude,$longitude?q=$latitude,$longitude(${Uri.encode(label)})")
        val intent = Intent(Intent.ACTION_VIEW, geoUri)
        return Intent.createChooser(intent, "Open location in...")
    }

    private fun isAppInstalled(context: Context, packageName: String): Boolean {
        return try {
            context.packageManager.getPackageInfo(packageName, 0)
            true
        } catch (e: PackageManager.NameNotFoundException) {
            false
        }
    }
}
```

### Map Picker Bottom Sheet

```kotlin
// ui/mapPicker/MapPickerBottomSheet.kt

package com.petsafety.app.ui.mapPicker

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Map
import androidx.compose.material.icons.filled.Navigation
import androidx.compose.material.icons.filled.Warning
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import com.petsafety.app.util.MapIntentBuilder

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun MapPickerBottomSheet(
    latitude: Double,
    longitude: Double,
    petName: String,
    isApproximate: Boolean,
    onDismiss: () -> Unit
) {
    val context = LocalContext.current
    val availableApps = remember { MapIntentBuilder.getAvailableMapApps(context) }

    ModalBottomSheet(onDismissRequest = onDismiss) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp)
        ) {
            Text(
                text = "📍 $petName Location",
                style = MaterialTheme.typography.headlineSmall
            )
            
            Spacer(modifier = Modifier.height(8.dp))
            
            Text(
                text = "%.6f, %.6f".format(latitude, longitude),
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
            
            if (isApproximate) {
                Spacer(modifier = Modifier.height(16.dp))
                Card(
                    colors = CardDefaults.cardColors(
                        containerColor = MaterialTheme.colorScheme.errorContainer
                    )
                ) {
                    Row(
                        modifier = Modifier.padding(12.dp)
                    ) {
                        Icon(
                            imageVector = Icons.Default.Warning,
                            contentDescription = null,
                            tint = MaterialTheme.colorScheme.error
                        )
                        Spacer(modifier = Modifier.width(8.dp))
                        Text(
                            text = "Approximate location (~500m). Search the surrounding area.",
                            style = MaterialTheme.typography.bodyMedium,
                            color = MaterialTheme.colorScheme.onErrorContainer
                        )
                    }
                }
            }
            
            Spacer(modifier = Modifier.height(24.dp))
            
            Text(
                text = "Open in",
                style = MaterialTheme.typography.titleMedium
            )
            
            Spacer(modifier = Modifier.height(8.dp))

            availableApps.forEach { app ->
                ListItem(
                    headlineContent = { Text(app.name) },
                    leadingContent = {
                        Icon(imageVector = Icons.Default.Map, contentDescription = null)
                    },
                    trailingContent = {
                        Icon(imageVector = Icons.Default.Navigation, contentDescription = "Open")
                    },
                    modifier = Modifier.clickable {
                        val intent = MapIntentBuilder.buildIntent(
                            mapApp = app,
                            latitude = latitude,
                            longitude = longitude,
                            label = "$petName Location"
                        )
                        context.startActivity(intent)
                        onDismiss()
                    }
                )
            }
            
            Spacer(modifier = Modifier.height(32.dp))
        }
    }
}
```

### AndroidManifest.xml Additions

```xml
<service
    android:name=".services.PetSafetyMessagingService"
    android:exported="false">
    <intent-filter>
        <action android:name="com.google.firebase.MESSAGING_EVENT" />
    </intent-filter>
</service>

<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />

<queries>
    <package android:name="com.google.android.apps.maps" />
    <package android:name="com.waze" />
    <intent>
        <action android:name="android.intent.action.VIEW" />
        <data android:scheme="geo" />
    </intent>
</queries>
```

---

## Web Implementation (project-tag)

### Location Consent Form

```typescript
// src/components/LocationConsentForm.tsx

import { useState } from 'react';
import './LocationConsentForm.css';

type LocationConsent = 'none' | 'approximate' | 'precise';

interface LocationData {
  latitude: number;
  longitude: number;
  accuracy_meters: number;
  is_approximate: boolean;
  consent_type: LocationConsent;
}

interface Props {
  onSubmit: (location: LocationData | null) => void;
  isSubmitting: boolean;
}

export function LocationConsentForm({ onSubmit, isSubmitting }: Props) {
  const [consent, setConsent] = useState<LocationConsent>('none');
  const [status, setStatus] = useState<'idle' | 'requesting' | 'ready' | 'error'>('idle');
  const [location, setLocation] = useState<LocationData | null>(null);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);

  const requestLocation = (consentType: LocationConsent) => {
    if (consentType === 'none') {
      setLocation(null);
      setStatus('ready');
      return;
    }

    setStatus('requesting');
    setErrorMessage(null);

    if (!navigator.geolocation) {
      setStatus('error');
      setErrorMessage('Location not supported by your browser');
      return;
    }

    const options: PositionOptions = {
      enableHighAccuracy: consentType === 'precise',
      timeout: 15000,
      maximumAge: consentType === 'approximate' ? 300000 : 60000,
    };

    navigator.geolocation.getCurrentPosition(
      (position) => {
        let { latitude, longitude } = position.coords;
        const accuracy = position.coords.accuracy;

        // Round for approximate (3 decimals = ~111m precision)
        if (consentType === 'approximate') {
          latitude = Math.round(latitude * 1000) / 1000;
          longitude = Math.round(longitude * 1000) / 1000;
        }

        const locationData: LocationData = {
          latitude,
          longitude,
          accuracy_meters: accuracy,
          is_approximate: consentType === 'approximate',
          consent_type: consentType,
        };

        setLocation(locationData);
        setStatus('ready');
      },
      (error) => {
        setStatus('error');
        switch (error.code) {
          case error.PERMISSION_DENIED:
            setErrorMessage('Location permission denied');
            break;
          case error.POSITION_UNAVAILABLE:
            setErrorMessage('Location unavailable');
            break;
          case error.TIMEOUT:
            setErrorMessage('Location request timed out');
            break;
          default:
            setErrorMessage('Could not get location');
        }
      },
      options
    );
  };

  const handleConsentChange = (newConsent: LocationConsent) => {
    setConsent(newConsent);
    setStatus('idle');
    setLocation(null);
    
    if (newConsent !== 'none') {
      requestLocation(newConsent);
    } else {
      setStatus('ready');
    }
  };

  const handleSubmit = () => {
    onSubmit(consent === 'none' ? null : location);
  };

  return (
    <div className="location-consent">
      <h3>📍 Share your location to help the owner</h3>
      
      <p className="privacy-note">
        Your location is shared <strong>only with the pet owner</strong> for this 
        notification. We do not store or track your location beyond 90 days.
        <a href="/privacy" target="_blank" rel="noopener noreferrer">Privacy Policy</a>
      </p>

      <div className="consent-options">
        <label className={`consent-option ${consent === 'none' ? 'selected' : ''}`}>
          <input
            type="radio"
            name="location-consent"
            value="none"
            checked={consent === 'none'}
            onChange={() => handleConsentChange('none')}
            disabled={isSubmitting}
          />
          <span className="option-content">
            <strong>Don't share location</strong>
            <small>Owner will still be notified of the scan</small>
          </span>
        </label>

        <label className={`consent-option ${consent === 'approximate' ? 'selected' : ''}`}>
          <input
            type="radio"
            name="location-consent"
            value="approximate"
            checked={consent === 'approximate'}
            onChange={() => handleConsentChange('approximate')}
            disabled={isSubmitting}
          />
          <span className="option-content">
            <strong>Share approximate area</strong>
            <small>~500 meter accuracy</small>
          </span>
        </label>

        <label className={`consent-option ${consent === 'precise' ? 'selected' : ''}`}>
          <input
            type="radio"
            name="location-consent"
            value="precise"
            checked={consent === 'precise'}
            onChange={() => handleConsentChange('precise')}
            disabled={isSubmitting}
          />
          <span className="option-content">
            <strong>Share exact location</strong>
            <small>Best chance of reuniting</small>
          </span>
        </label>
      </div>

      {status === 'requesting' && (
        <div className="status-message loading">
          <span className="spinner"></span> Getting location...
        </div>
      )}

      {status === 'error' && errorMessage && (
        <div className="status-message error">
          ⚠️ {errorMessage}. You can still notify without location.
        </div>
      )}

      {status === 'ready' && location && (
        <div className="status-message success">
          ✅ Location ready ({location.is_approximate ? 'approximate' : 'precise'})
        </div>
      )}

      <button
        className="btn btn-primary"
        onClick={handleSubmit}
        disabled={isSubmitting || (consent !== 'none' && status !== 'ready' && status !== 'error')}
      >
        {isSubmitting ? 'Notifying...' : 'Notify Owner'}
      </button>
    </div>
  );
}
```

### Scan Page

```typescript
// src/pages/ScanPage.tsx

import { useState, useEffect } from 'react';
import { useParams } from 'react-router-dom';
import { LocationConsentForm } from '../components/LocationConsentForm';
import { PetCard } from '../components/PetCard';
import { api } from '../api';

export function ScanPage() {
  const { code } = useParams<{ code: string }>();
  const [pet, setPet] = useState<Pet | null>(null);
  const [loading, setLoading] = useState(true);
  const [submitting, setSubmitting] = useState(false);
  const [submitted, setSubmitted] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (code) {
      api.getPetByCode(code)
        .then(setPet)
        .catch(() => setError('Tag not found'))
        .finally(() => setLoading(false));
    }
  }, [code]);

  const handleSubmit = async (location: LocationData | null) => {
    if (!code) return;

    setSubmitting(true);
    setError(null);

    try {
      await api.submitScan({
        code,
        location: location || undefined,
      });
      setSubmitted(true);
    } catch (err: any) {
      if (err.status === 429) {
        setError('Too many scans. Please try again later.');
      } else {
        setError('Failed to notify owner. Please try again.');
      }
    } finally {
      setSubmitting(false);
    }
  };

  if (loading) {
    return <div className="loading">Loading...</div>;
  }

  if (error && !pet) {
    return <div className="error-page">{error}</div>;
  }

  if (!pet) {
    return <div className="error-page">Tag not found</div>;
  }

  return (
    <div className="scan-page">
      <PetCard pet={pet} />
      
      {pet.is_missing && (
        <div className="alert alert-warning">
          ⚠️ This pet is reported missing! Please help reunite them with their owner.
        </div>
      )}

      {!submitted ? (
        <>
          <LocationConsentForm 
            onSubmit={handleSubmit} 
            isSubmitting={submitting}
          />
          {error && <div className="error-message">{error}</div>}
        </>
      ) : (
        <div className="scan-success">
          <h3>✅ Owner Notified!</h3>
          <p>The owner has received a notification. Thank you for helping!</p>
        </div>
      )}
    </div>
  );
}
```

---

## Testing Requirements

### Backend Tests

```typescript
describe('POST /api/v1/scans', () => {
  it('should accept scan without location', async () => {});
  it('should accept scan with approximate location', async () => {});
  it('should accept scan with precise location', async () => {});
  it('should reject invalid coordinates', async () => {});
  it('should reject PII fields (finder_name, finder_phone, etc)', async () => {});
  it('should enforce rate limiting', async () => {});
  it('should validate consent_type matches is_approximate', async () => {});
});

describe('NotificationService', () => {
  it('should send FCM and email for precise location', async () => {});
  it('should send FCM and email for approximate location', async () => {});
  it('should send FCM and email without location', async () => {});
  it('should handle FCM failure gracefully', async () => {});
  it('should handle email failure gracefully', async () => {});
  it('should log all notification attempts', async () => {});
});

describe('Data retention', () => {
  it('should delete scans older than 90 days', async () => {});
  it('should delete notification logs older than 90 days', async () => {});
});
```

### iOS Tests

```swift
final class NotificationHandlerTests: XCTestCase {
    func testHandlePreciseLocation() {}
    func testHandleApproximateLocation() {}
    func testHandleNoLocation() {}
}

final class MapAppPickerTests: XCTestCase {
    func testAppleMapsURL() {}
    func testGoogleMapsURL() {}
    func testWazeURL() {}
}
```

### Android Tests

```kotlin
class MapIntentBuilderTest {
    @Test fun `builds correct Google Maps URI`() {}
    @Test fun `builds correct Waze URI`() {}
    @Test fun `encodes special characters in label`() {}
}

class FCMTokenRepositoryTest {
    @Test fun `registers token when logged in`() = runTest {}
    @Test fun `skips registration when logged out`() = runTest {}
}
```

---

## Acceptance Criteria

### Must Pass Before Merge

**Backend:**
- [ ] API rejects requests containing PII fields (finder_name, etc)
- [ ] API validates coordinate bounds
- [ ] API validates consent_type consistency
- [ ] Rate limiting works (5 scans/pet/IP/hour)
- [ ] FCM notifications sent successfully
- [ ] Email sent with correct template based on location tier
- [ ] Notification logs created for all attempts
- [ ] Invalid FCM tokens cleaned up
- [ ] Data retention job deletes records >90 days

**iOS:**
- [ ] FCM token registers on login
- [ ] Push notification displays correctly for all 3 tiers
- [ ] Map picker shows approximate warning when relevant
- [ ] All 3 map apps open correctly

**Android:**
- [ ] FCM token registers on login
- [ ] Notification displays with "Open Maps" action
- [ ] Map picker shows approximate warning
- [ ] All installed map apps open correctly

**Web:**
- [ ] Default consent is "Don't share"
- [ ] Location permission requested only after selection
- [ ] Approximate coordinates are rounded
- [ ] Scan submits correctly for all 3 tiers
- [ ] Privacy policy link visible

**GDPR:**
- [ ] No PII stored in scans table
- [ ] Location only stored with explicit consent_type
- [ ] 90-day retention enforced
- [ ] Privacy policy text accurate

---

## Environment Variables

### Backend
```
FIREBASE_PROJECT_ID=
FIREBASE_CLIENT_EMAIL=
FIREBASE_PRIVATE_KEY=
```

### iOS
```
# GoogleService-Info.plist from Firebase Console
```

### Android
```
# google-services.json from Firebase Console
```

---

## Rollout Plan

1. Deploy backend to staging, test with internal devices
2. Release iOS TestFlight build, verify FCM
3. Release Android internal track, verify FCM
4. Deploy web to staging, test full flow
5. Production deployment (backend → web → mobile)
6. Monitor Sentry + notification logs for 24 hours

---

## Questions to Resolve

- [ ] Firebase project: existing or new dedicated project?
- [ ] Email provider: AWS SES, SendGrid, or other?
- [ ] Rate limit: 5/hour acceptable or adjust?
