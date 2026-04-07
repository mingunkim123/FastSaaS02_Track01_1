# Flutter User Profile & Logout + RecordPage Layout Fix

**Date:** 2026-04-07  
**Status:** Approved  
**Platform:** Flutter (Active UI)

---

## Overview

Three focused improvements to the Flutter expense tracker:

1. **User Profile & Logout UI** — Add a user profile bottom sheet accessible from AppBar
2. **User Profile Button** — Avatar icon trigger in top-right corner
3. **RecordPage Button Layout Fix** — Fix the vertical-to-horizontal snap issue on SegmentedButton

---

## 1. User Profile Bottom Sheet

### Requirement

Add a bottom sheet modal that displays user profile information and provides logout functionality.

### Design

**Trigger:** Avatar icon button in AppBar (top-right corner)

**Modal Content:**
- User avatar (larger display, centered)
- User name (displayed prominently below avatar)
- User email (secondary text below name)
- Logout button (full-width, red/destructive styling)
- Close button (X icon in top-right of sheet)

**User Data Sources:**
Display user data from Supabase session, specifically:
- `name` — from user metadata or email fallback
- `email` — user's email address
- `avatarUrl` — profile picture URL from user metadata

Hidden/not displayed:
- `id`, `provider`, `createdAt` (technical/internal)

### Interaction Flow

1. User taps avatar button in AppBar
2. Bottom sheet slides up from bottom with backdrop overlay
3. Modal shows profile info + logout button
4. User can:
   - Tap logout button → calls `signOutProvider` → redirects to login
   - Tap X button → closes sheet
   - Tap backdrop → closes sheet
5. Sheet animates closed on logout or close action

### Implementation Approach

**Components to create:**
1. `UserProfileSheet` — Widget displaying the bottom sheet modal content
2. `UserProfileButton` — Widget displaying avatar button trigger

**Data flow:**
- Pull user data from `currentUserProvider` (Riverpod)
- Call `signOutProvider` on logout action (already exists in auth_provider.dart)
- Manage sheet open/close state locally or via a simple StateNotifier

**Styling:**
- Use existing AppTheme colors and border radius
- Red color for logout button (AppTheme.errorColor or similar)
- Match existing bottom sheet design patterns in app
- Responsive to mobile screen sizes (flutter_app is mobile-first)

---

## 2. User Profile Button in AppBar

### Requirement

Add a user profile button accessible from the app's AppBar, visible on all authenticated pages.

### Design

**Location:** AppBar top-right corner (fixed position on all authenticated pages)

**Button:**
- Circular avatar displaying user's profile picture or initials
- 40x40 size (standard mobile button size)
- Border around avatar
- Tap opens UserProfileSheet

**Visibility:**
- Only shows when user is authenticated
- Hidden on login/auth pages
- Present on all authenticated routes (record, calendar, stats, ai)

**Implementation Approach:**

**Where to place:**
- Integrate into `BottomNavShell` or create a shared `AppBar` widget
- Add to authenticated page AppBar via `actions` parameter
- Or create a wrapper widget that includes AppBar with UserProfileButton

**Data flow:**
- Check `isAuthenticatedProvider` or `currentUserProvider` to determine visibility
- Pass user data (name, email, avatarUrl) from `currentUserProvider`
- Manage sheet open/close state

---

## 3. RecordPage Button Layout Fix

### Problem

The SegmentedButton (expense/income toggle) on RecordPage renders vertically on initial page load, then snaps to horizontal layout after a moment. This indicates a layout calculation timing issue.

### Root Cause

The button's layout direction may not be calculated correctly on first render, defaulting to vertical before being corrected.

### Solution

Ensure the SegmentedButton container has proper constraints and layout properties set from the start. This may involve:

1. Wrapping SegmentedButton in a `SizedBox` with explicit width (full width)
2. Ensuring parent container has proper `mainAxisSize` or `mainAxisAlignment`
3. Checking if SegmentedButton itself needs explicit direction or width constraints

The fix should ensure buttons render horizontally immediately on first load with no snap/shift.

### Expected Result

Buttons render horizontally on first load, no snap/shift to horizontal layout.

---

## Implementation Plan

See `docs/superpowers/plans/2026-04-07-flutter-user-profile-logout-plan.md` for the detailed step-by-step implementation.
