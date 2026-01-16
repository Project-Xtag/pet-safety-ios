# Offline Mode Test Plan - Pet Safety iOS App

## Document Information
- **Phase**: Phase 4 - Offline Mode Implementation
- **Version**: 1.0
- **Date**: 2026-01-14
- **Testing Scope**: iOS App Only (Core Data + Sync)

## Overview
This document outlines the comprehensive testing strategy for the offline mode implementation in the Pet Safety iOS app. The implementation includes Core Data persistence, network monitoring, action queuing, and automatic synchronization.

---

## 1. Test Environment Setup

### Prerequisites
- Xcode 15.0 or later
- iOS 17.0+ device or simulator
- Active backend API connection
- Network Link Conditioner tool (for network simulation)
- TestFlight distribution (for real device testing)

### Test Devices
- [ ] iPhone 14 Pro (iOS 17.0) - Simulator
- [ ] iPhone 15 Pro (iOS 17.4) - Physical Device
- [ ] iPad Air (iOS 17.2) - Simulator
- [ ] Various network conditions (WiFi, Cellular, Offline)

### Test Data Requirements
- Test user account with authentication
- At least 3 test pets with photos
- At least 2 active missing pet alerts
- Clean Core Data state before each test suite

---

## 2. Unit Tests

### 2.1 NetworkMonitor Tests
**File**: `NetworkMonitor.swift`

#### Test Cases:
1. **Test Network Detection on Launch**
   - [ ] Verify `isConnected` reports correct initial state
   - [ ] Verify `connectionType` detects WiFi correctly
   - [ ] Verify `connectionType` detects Cellular correctly

2. **Test Network State Changes**
   - [ ] Enable airplane mode → verify `isConnected` becomes false
   - [ ] Disable airplane mode → verify `isConnected` becomes true
   - [ ] Switch WiFi → Cellular → verify `connectionType` updates
   - [ ] Verify notification posted on state change

3. **Test Connection Quality Detection**
   - [ ] Verify `isExpensive` detects cellular correctly
   - [ ] Verify `isConstrained` detects limited connections

**Expected Results**: All network state changes detected within 2 seconds

---

### 2.2 OfflineDataManager Tests
**File**: `OfflineDataManager.swift`

#### Test Cases:

**Pet Operations:**
1. **Save Single Pet**
   - [ ] Save new pet → verify saved in Core Data
   - [ ] Save existing pet → verify updated, not duplicated
   - [ ] Save pet with nil values → verify handled correctly
   - [ ] Verify `lastSyncedAt` timestamp updated

2. **Fetch Pets**
   - [ ] Fetch all pets → verify sorted by name
   - [ ] Fetch empty database → verify returns empty array
   - [ ] Fetch after save → verify data persisted

3. **Delete Pet**
   - [ ] Delete existing pet → verify removed from Core Data
   - [ ] Delete non-existent pet → verify no error thrown
   - [ ] Delete pet → verify associated data cascade deleted

**Alert Operations:**
4. **Save Alert**
   - [ ] Save new alert → verify saved correctly
   - [ ] Update existing alert → verify updated
   - [ ] Save alert without pet → verify handles gracefully

5. **Fetch Alerts**
   - [ ] Fetch all alerts → verify sorted by createdAt
   - [ ] Fetch alerts for specific pet → verify correct filtering
   - [ ] Fetch empty → verify returns empty array

**Action Queue Operations:**
6. **Queue Action**
   - [ ] Queue mark lost action → verify saved with pending status
   - [ ] Queue report sighting → verify data serialized correctly
   - [ ] Verify UUID generated for each action
   - [ ] Verify retry count initialized to 0

7. **Fetch Pending Actions**
   - [ ] Fetch pending actions → verify only pending returned
   - [ ] Verify sorted by createdAt (FIFO order)
   - [ ] Fetch empty queue → verify empty array returned

8. **Complete Action**
   - [ ] Complete action → verify removed from queue
   - [ ] Complete non-existent action → verify no error

9. **Fail Action**
   - [ ] Fail action with retry → verify retry count incremented
   - [ ] Fail action → verify error message stored
   - [ ] Fail action 5 times → verify deleted from queue

**Expected Results**: All CRUD operations complete in < 100ms

---

### 2.3 SyncService Tests
**File**: `SyncService.swift`

#### Test Cases:

1. **Action Queuing**
   - [ ] Queue action when offline → verify added to queue
   - [ ] Queue action when online → verify immediate sync attempted
   - [ ] Verify `pendingActionsCount` updates correctly

2. **Sync Triggers**
   - [ ] Network reconnects → verify auto-sync triggered
   - [ ] Manual sync button → verify sync executes
   - [ ] Timer (5 min) → verify auto-sync triggered
   - [ ] Verify only one sync runs at a time (`isSyncing` check)

3. **Process Queued Actions**
   - [ ] Process mark lost action → verify API called correctly
   - [ ] Process mark found action → verify API called correctly
   - [ ] Process report sighting → verify API called correctly
   - [ ] Process multiple actions → verify sequential processing
   - [ ] Action fails → verify retry logic, error stored
   - [ ] Action succeeds → verify removed from queue

4. **Fetch Remote Data**
   - [ ] Fetch pets → verify cached locally
   - [ ] Fetch alerts → verify cached locally
   - [ ] Verify `lastSyncDate` updated after successful sync

5. **Sync Status**
   - [ ] Verify `syncStatus` shows "Syncing..." during sync
   - [ ] Verify `syncStatus` shows "Sync completed" on success
   - [ ] Verify `syncStatus` shows error message on failure

**Expected Results**: All actions sync within 10 seconds of network reconnection

---

## 3. Integration Tests

### 3.1 Offline Data Persistence

**Scenario 1: Fetch and Cache Pets**
1. **Setup**: Start with online connection, clean Core Data
2. **Steps**:
   - [ ] Launch app → Navigate to Pets List
   - [ ] Wait for pets to load from API
   - [ ] Verify pets displayed in UI
   - [ ] Check Core Data → verify pets cached
3. **Expected**: Pets cached with `lastSyncedAt` timestamp

**Scenario 2: Load from Cache When Offline**
1. **Setup**: Complete Scenario 1, then enable airplane mode
2. **Steps**:
   - [ ] Force quit app
   - [ ] Enable airplane mode
   - [ ] Launch app → Navigate to Pets List
   - [ ] Verify pets load from cache
   - [ ] Verify "Showing cached data (offline)" message shown
   - [ ] Verify offline indicator displayed
3. **Expected**: Pets load instantly from cache, UI shows offline status

**Scenario 3: Cache Persists Across App Restarts**
1. **Setup**: Complete Scenario 2
2. **Steps**:
   - [ ] Force quit app while offline
   - [ ] Relaunch app
   - [ ] Navigate to Pets List
   - [ ] Verify cached pets still available
3. **Expected**: Cached data persists, no data loss

---

### 3.2 Action Queue When Offline

**Scenario 4: Mark Pet Missing While Offline**
1. **Setup**: App offline, user has pets
2. **Steps**:
   - [ ] Navigate to Pets List
   - [ ] Tap "Report Missing" quick action
   - [ ] Select a pet
   - [ ] Fill in location, description
   - [ ] Submit form
   - [ ] Verify "Action queued" message shown
   - [ ] Verify pet shows as missing in UI (optimistic update)
   - [ ] Check Core Data → verify action queued
   - [ ] Verify offline indicator shows pending action count
3. **Expected**: Action queued, pet status updated locally, UI reflects offline state

**Scenario 5: Report Sighting While Offline**
1. **Setup**: App offline, active missing pet alert exists
2. **Steps**:
   - [ ] Navigate to Alerts List
   - [ ] Select a missing pet alert
   - [ ] Tap "Report Sighting"
   - [ ] Fill in sighting details (location, notes, contact)
   - [ ] Submit form
   - [ ] Verify "Sighting report queued" message
   - [ ] Check Core Data → verify action queued
   - [ ] Verify pending count incremented
3. **Expected**: Sighting queued, confirmation shown, no errors

**Scenario 6: Multiple Actions Queued**
1. **Setup**: App offline
2. **Steps**:
   - [ ] Mark pet A as missing
   - [ ] Report sighting for pet B
   - [ ] Mark pet C as missing
   - [ ] Verify all 3 actions queued
   - [ ] Verify pending count = 3
   - [ ] Expand offline indicator → verify actions listed
3. **Expected**: All actions queued in order, no data loss

---

### 3.3 Sync When Coming Back Online

**Scenario 7: Automatic Sync on Reconnection**
1. **Setup**: Complete Scenario 6 (3 queued actions)
2. **Steps**:
   - [ ] Disable airplane mode (restore connection)
   - [ ] Wait for network detection (< 2 seconds)
   - [ ] Verify offline indicator changes to "Syncing..."
   - [ ] Verify actions processed (< 10 seconds)
   - [ ] Verify pending count goes to 0
   - [ ] Verify offline indicator shows "Online" or hides
   - [ ] Check backend → verify all 3 actions executed
3. **Expected**: All actions sync automatically, UI updates, no user intervention needed

**Scenario 8: Manual Sync**
1. **Setup**: App online, but sync not triggered automatically
2. **Steps**:
   - [ ] Expand offline indicator
   - [ ] Tap "Sync Now" button
   - [ ] Verify "Syncing..." status shown
   - [ ] Verify progress indicator displayed
   - [ ] Wait for completion
   - [ ] Verify "Sync completed" message
   - [ ] Verify `lastSyncDate` updated
3. **Expected**: Manual sync completes successfully, status updates

**Scenario 9: Sync Failure and Retry**
1. **Setup**: Queue action, simulate network error during sync
2. **Steps**:
   - [ ] Queue action while offline
   - [ ] Go online
   - [ ] Use Network Link Conditioner → set 100% packet loss
   - [ ] Wait for auto-sync attempt
   - [ ] Verify sync fails
   - [ ] Verify action remains in queue
   - [ ] Verify retry count incremented
   - [ ] Restore normal network
   - [ ] Wait for next sync attempt
   - [ ] Verify action eventually succeeds
3. **Expected**: Retry logic works, action not lost, eventually syncs

**Scenario 10: Periodic Auto-Sync**
1. **Setup**: App online, last sync > 5 minutes ago
2. **Steps**:
   - [ ] Launch app
   - [ ] Wait 5 minutes (or use time manipulation)
   - [ ] Verify auto-sync triggered
   - [ ] Verify fresh data fetched
   - [ ] Verify cache updated
3. **Expected**: Auto-sync runs every 5 minutes when online

---

### 3.4 Conflict Resolution

**Scenario 11: Local and Remote Data Diverged**
1. **Setup**: Mark pet as missing offline, someone else marks found online
2. **Steps**:
   - [ ] Device A: Offline, mark pet as missing
   - [ ] Device B: Online, mark same pet as found
   - [ ] Device A: Go online, trigger sync
   - [ ] Observe behavior
   - [ ] Verify no crash or data corruption
3. **Expected**: Conflict handled gracefully (server wins, or user prompted)

**Scenario 12: Duplicate Actions**
1. **Setup**: Queue same action twice while offline
2. **Steps**:
   - [ ] Offline, mark pet A as missing
   - [ ] Queue second action for same pet
   - [ ] Go online
   - [ ] Verify both actions processed OR second rejected
   - [ ] Verify no duplicate alerts created
3. **Expected**: Duplicates handled gracefully, no duplicate data

---

## 4. UI/UX Tests

### 4.1 Offline Indicator

**Scenario 13: Indicator Visibility**
1. **Steps**:
   - [ ] Launch app online → verify indicator NOT shown (or shows green/online)
   - [ ] Go offline → verify indicator appears with red/offline status
   - [ ] Queue action → verify indicator shows pending count
   - [ ] Go online → verify indicator shows "Syncing..."
   - [ ] After sync → verify indicator hides or shows green
2. **Expected**: Indicator behavior matches network and sync state

**Scenario 14: Expanded Details**
1. **Steps**:
   - [ ] Go offline, queue 2 actions
   - [ ] Tap offline indicator to expand
   - [ ] Verify shows "2 actions queued"
   - [ ] Verify shows last sync time
   - [ ] Verify shows "Sync Now" button
   - [ ] Tap "Sync Now" while offline → verify disabled or shows error
3. **Expected**: Expanded view shows accurate information

**Scenario 15: Indicator on Multiple Screens**
1. **Steps**:
   - [ ] Go offline
   - [ ] Navigate to Pets List → verify indicator shown
   - [ ] Navigate to Alerts List → verify indicator shown
   - [ ] Navigate to Missing Alerts tab → verify indicator shown
   - [ ] Navigate to Profile → verify indicator shown/hidden based on design
2. **Expected**: Indicator appears on all relevant data-driven screens

---

### 4.2 User Feedback Messages

**Scenario 16: Offline Actions Feedback**
1. **Steps**:
   - [ ] Go offline
   - [ ] Mark pet as missing
   - [ ] Verify user sees "Action queued. Will sync when online." message
   - [ ] Report sighting
   - [ ] Verify user sees "Sighting report queued. Will sync when online." message
2. **Expected**: Clear feedback for all offline actions

**Scenario 17: Error Messages**
1. **Steps**:
   - [ ] Trigger various error conditions:
     - [ ] Sync fails due to network error
     - [ ] Sync fails due to server error (500)
     - [ ] Sync fails due to auth error (401)
   - [ ] Verify appropriate error messages shown
   - [ ] Verify errors don't crash app
2. **Expected**: User-friendly error messages, no crashes

---

## 5. Performance Tests

### 5.1 Data Loading Performance

**Scenario 18: Large Dataset Loading**
1. **Setup**: Account with 50+ pets, 20+ alerts
2. **Steps**:
   - [ ] Time fetch from API (online)
   - [ ] Time fetch from cache (offline)
   - [ ] Measure UI rendering time
3. **Expected**:
   - API fetch: < 3 seconds
   - Cache fetch: < 500ms
   - UI render: < 1 second

**Scenario 19: Sync Performance**
1. **Setup**: 10 queued actions
2. **Steps**:
   - [ ] Measure time to sync all actions
   - [ ] Verify no UI blocking
   - [ ] Verify progress shown
3. **Expected**: All actions sync within 30 seconds, UI remains responsive

---

### 5.2 Battery and Resource Usage

**Scenario 20: Background Monitoring**
1. **Steps**:
   - [ ] Launch app
   - [ ] Monitor battery usage over 1 hour
   - [ ] Monitor CPU usage
   - [ ] Verify network monitor doesn't drain battery excessively
3. **Expected**: Background monitoring < 2% battery per hour

---

## 6. Edge Cases and Stress Tests

### 6.1 Network Instability

**Scenario 21: Rapid Connection Changes**
1. **Steps**:
   - [ ] Toggle airplane mode on/off rapidly (10 times)
   - [ ] Verify app doesn't crash
   - [ ] Verify sync logic handles gracefully
   - [ ] Verify no duplicate syncs triggered
2. **Expected**: App stable, no crashes, sync queue not corrupted

**Scenario 22: Poor Network Conditions**
1. **Steps**:
   - [ ] Use Network Link Conditioner → set "Very Bad Network"
   - [ ] Queue action
   - [ ] Trigger sync
   - [ ] Verify timeout handling
   - [ ] Verify retry scheduled
2. **Expected**: Timeouts handled, actions retry on next attempt

---

### 6.2 Data Integrity

**Scenario 23: App Termination During Sync**
1. **Steps**:
   - [ ] Start sync with multiple actions
   - [ ] Force quit app mid-sync
   - [ ] Relaunch app
   - [ ] Verify partial sync state recovered
   - [ ] Verify remaining actions still in queue
   - [ ] Complete sync
2. **Expected**: No data corruption, incomplete actions remain queued

**Scenario 24: Storage Full**
1. **Steps**:
   - [ ] Fill device storage to near capacity
   - [ ] Attempt to cache data
   - [ ] Verify error handled gracefully
   - [ ] Verify user notified of storage issue
2. **Expected**: Graceful degradation, no crash

---

## 7. Backend Compatibility Tests

### 7.1 API Endpoint Verification

**Scenario 25: Required Endpoints Available**
1. **API Endpoints to Verify**:
   - [ ] `GET /api/pets` - Fetch pets
   - [ ] `POST /api/pets` - Create pet
   - [ ] `PUT /api/pets/:id` - Update pet
   - [ ] `DELETE /api/pets/:id` - Delete pet
   - [ ] `GET /api/alerts` - Fetch alerts
   - [ ] `POST /api/alerts` - Create missing pet alert
   - [ ] `PUT /api/alerts/:id` - Update alert status
   - [ ] `POST /api/alerts/:id/sightings` - Report sighting
   - [ ] `PUT /api/pets/:id/found` - Mark pet as found
2. **Verification**:
   - [ ] Test each endpoint with Postman/curl
   - [ ] Verify request/response format matches iOS expectations
   - [ ] Verify authentication works
   - [ ] Verify error responses are handled

**Expected**: All required endpoints functional, properly authenticated

---

### 7.2 Data Synchronization Accuracy

**Scenario 26: End-to-End Data Sync**
1. **Steps**:
   - [ ] iOS: Queue action offline
   - [ ] iOS: Go online, sync
   - [ ] Backend: Verify action received and processed
   - [ ] Web App: Refresh, verify data appears
   - [ ] iOS: Pull to refresh, verify data consistent
2. **Expected**: Data consistent across iOS, backend, and web app

**Scenario 27: Timestamp Handling**
1. **Steps**:
   - [ ] Verify `createdAt` and `updatedAt` timestamps
   - [ ] Check timezone handling
   - [ ] Verify date formatting matches between platforms
2. **Expected**: Timestamps consistent, no timezone issues

---

## 8. Regression Tests

**After any code changes, verify:**
- [ ] All existing features still work
- [ ] Online mode (without offline) still functions normally
- [ ] Authentication flow unaffected
- [ ] Push notifications unaffected
- [ ] Photo upload still works
- [ ] Navigation flows intact

---

## 9. Test Execution Checklist

### Pre-Testing
- [ ] All files added to Xcode project
- [ ] Project builds without errors
- [ ] Core Data model compiled
- [ ] Backend environment configured
- [ ] Test user accounts created

### During Testing
- [ ] Document all failures with screenshots
- [ ] Note performance metrics
- [ ] Log network traffic for debugging
- [ ] Record video of critical flows

### Post-Testing
- [ ] All critical tests passing (Scenarios 1-17)
- [ ] Performance tests meet expectations
- [ ] Edge cases handled
- [ ] Backend compatibility verified
- [ ] Regression tests passing

---

## 10. Success Criteria

**Must Pass (Critical):**
- ✅ All pets and alerts cache locally
- ✅ Offline indicator shows correct status
- ✅ Actions queue when offline
- ✅ Auto-sync on reconnection
- ✅ No data loss in any scenario
- ✅ No crashes or freezes

**Should Pass (Important):**
- ✅ Sync completes within 10 seconds
- ✅ Cache loads within 500ms
- ✅ Retry logic handles failures
- ✅ UI/UX feedback clear and helpful

**Nice to Have (Enhancement):**
- ⭐ Battery usage minimal
- ⭐ Conflict resolution handles edge cases
- ⭐ Advanced error recovery

---

## 11. Known Limitations

Document any known limitations during testing:
1. Conflict resolution strategy: [TBD during testing]
2. Maximum queued actions: [TBD during testing]
3. Photo upload while offline: [Not implemented in Phase 4]
4. Background sync: [Not implemented in Phase 4]

---

## 12. Test Report Template

After completing tests, create a report with:

### Test Summary
- Total scenarios: [X]
- Passed: [X]
- Failed: [X]
- Blocked: [X]
- Pass rate: [X%]

### Critical Issues Found
1. [Issue description]
   - Severity: Critical/High/Medium/Low
   - Steps to reproduce
   - Expected vs Actual
   - Screenshots/logs

### Performance Metrics
- Average cache load time: [X ms]
- Average sync time: [X seconds]
- Battery usage: [X% per hour]

### Recommendations
- [Improvement suggestions]
- [Priority fixes needed]
- [Future enhancements]

---

## 13. Next Steps After Testing

1. **Fix Critical Issues**: Address any test failures
2. **Optimize Performance**: If metrics don't meet expectations
3. **Update Documentation**: Based on test findings
4. **User Acceptance Testing**: Deploy to TestFlight for beta testing
5. **Monitor Production**: Set up analytics for offline mode usage

---

**Document Owner**: Development Team
**Last Updated**: 2026-01-14
**Next Review**: After test execution
