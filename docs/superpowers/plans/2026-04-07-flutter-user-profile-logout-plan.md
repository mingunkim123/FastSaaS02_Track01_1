# Flutter User Profile & Logout + RecordPage Layout Fix Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add user profile bottom sheet with logout to Flutter app and fix RecordPage SegmentedButton layout snap issue.

**Architecture:** 
- Create two new widgets (`UserProfileSheet` and `UserProfileButton`) for the profile UI
- Integrate UserProfileButton into BottomNavShell or page-level AppBar
- Use existing Riverpod providers (`currentUserProvider`, `signOutProvider`) for data and logout
- Fix RecordPage SegmentedButton container with explicit width constraints

**Tech Stack:** Flutter, Riverpod, GoRouter, Supabase

---

## File Structure

**New files:**
- `flutter_app/lib/shared/widgets/user_profile_sheet.dart` — Bottom sheet modal displaying user profile
- `flutter_app/lib/shared/widgets/user_profile_button.dart` — Avatar button trigger for profile sheet

**Modified files:**
- `flutter_app/lib/shared/widgets/bottom_nav_shell.dart` — Add AppBar with UserProfileButton
- `flutter_app/lib/features/record/record_page.dart` — Fix SegmentedButton layout with explicit width

---

## Task 1: Create UserProfileSheet Widget

**Files:**
- Create: `flutter_app/lib/shared/widgets/user_profile_sheet.dart`

- [ ] **Step 1: Create the UserProfileSheet widget file**

Create `flutter_app/lib/shared/widgets/user_profile_sheet.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_app/core/theme/app_theme.dart';
import 'package:flutter_app/shared/providers/auth_provider.dart';

/// Bottom sheet widget displaying user profile information
/// Shows user avatar, name, email, and logout button
class UserProfileSheet extends ConsumerWidget {
  const UserProfileSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);

    if (currentUser == null) {
      return const SizedBox.shrink();
    }

    // Extract user data
    final name = currentUser.userMetadata?['name'] as String? ?? currentUser.email ?? 'User';
    final email = currentUser.email ?? '';
    final avatarUrl = currentUser.userMetadata?['avatar_url'] as String?;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(AppTheme.borderRadiusLarge),
          topRight: Radius.circular(AppTheme.borderRadiusLarge),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header with close button
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(width: 48), // Spacer for centering
                Text(
                  '프로필', // Profile
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                  constraints: const BoxConstraints(
                    minWidth: 48,
                    minHeight: 48,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Content
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Avatar
                if (avatarUrl != null && avatarUrl.isNotEmpty)
                  ClipOval(
                    child: Image.network(
                      avatarUrl,
                      width: 64,
                      height: 64,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return _buildAvatarFallback(name);
                      },
                    ),
                  )
                else
                  _buildAvatarFallback(name),
                const SizedBox(height: 16),
                // Name
                Text(
                  name,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                // Email
                if (email.isNotEmpty)
                  Text(
                    email,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                    textAlign: TextAlign.center,
                  ),
                const SizedBox(height: 24),
                // Logout button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () => _handleLogout(context, ref),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.errorColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppTheme.borderRadiusMedium,
                        ),
                      ),
                    ),
                    child: const Text(
                      '로그아웃', // Logout
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  /// Build avatar fallback with initials
  Widget _buildAvatarFallback(String name) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initial,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w600,
            color: AppTheme.primaryColor,
          ),
        ),
      ),
    );
  }

  /// Handle logout action
  Future<void> _handleLogout(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(signOutProvider.future);
      if (context.mounted) {
        Navigator.of(context).pop(); // Close the sheet
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('로그아웃 실패: $e')),
        );
      }
    }
  }
}
```

- [ ] **Step 2: Verify the file is created with no syntax errors**

```bash
cd flutter_app && flutter analyze lib/shared/widgets/user_profile_sheet.dart
```

Expected: No errors or warnings related to the UserProfileSheet file.

---

## Task 2: Create UserProfileButton Widget

**Files:**
- Create: `flutter_app/lib/shared/widgets/user_profile_button.dart`

- [ ] **Step 1: Create the UserProfileButton widget file**

Create `flutter_app/lib/shared/widgets/user_profile_button.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_app/shared/providers/auth_provider.dart';
import 'package:flutter_app/shared/widgets/user_profile_sheet.dart';

/// Button widget displaying user avatar in AppBar
/// Tapping opens the user profile bottom sheet
class UserProfileButton extends ConsumerWidget {
  const UserProfileButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final isAuthenticated = ref.watch(isAuthenticatedProvider);

    // Only show if user is authenticated
    if (!isAuthenticated || currentUser == null) {
      return const SizedBox.shrink();
    }

    final name = currentUser.userMetadata?['name'] as String? ?? currentUser.email ?? 'User';
    final avatarUrl = currentUser.userMetadata?['avatar_url'] as String?;

    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: GestureDetector(
        onTap: () {
          showModalBottomSheet(
            context: context,
            builder: (context) => const UserProfileSheet(),
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            isScrollControlled: false,
          );
        },
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.grey[300] ?? Colors.grey,
              width: 2,
            ),
          ),
          child: ClipOval(
            child: avatarUrl != null && avatarUrl.isNotEmpty
                ? Image.network(
                    avatarUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return _buildAvatarFallback(name);
                    },
                  )
                : _buildAvatarFallback(name),
          ),
        ),
      ),
    );
  }

  /// Build avatar fallback with initials
  Widget _buildAvatarFallback(String name) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return Container(
      color: Colors.grey[200],
      child: Center(
        child: Text(
          initial,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Verify the file is created with no syntax errors**

```bash
cd flutter_app && flutter analyze lib/shared/widgets/user_profile_button.dart
```

Expected: No errors or warnings.

---

## Task 3: Integrate UserProfileButton into BottomNavShell

**Files:**
- Modify: `flutter_app/lib/shared/widgets/bottom_nav_shell.dart`

- [ ] **Step 1: Add import for UserProfileButton**

Add this import at the top of the file (after other imports):

```dart
import 'package:flutter_app/shared/widgets/user_profile_button.dart';
```

- [ ] **Step 2: Add AppBar with UserProfileButton to Scaffold**

In the `_BottomNavShellState.build()` method, modify the Scaffold to include an appBar:

Change from:
```dart
return Scaffold(
  body: widget.child,
  bottomNavigationBar: NavigationBar(
```

To:
```dart
return Scaffold(
  appBar: AppBar(
    elevation: 0,
    automaticallyImplyLeading: false,
    actions: const [
      UserProfileButton(),
    ],
  ),
  body: widget.child,
  bottomNavigationBar: NavigationBar(
```

- [ ] **Step 3: Verify the changes**

```bash
cd flutter_app && flutter analyze lib/shared/widgets/bottom_nav_shell.dart
```

Expected: No errors or warnings.

---

## Task 4: Fix RecordPage SegmentedButton Layout

**Files:**
- Modify: `flutter_app/lib/features/record/record_page.dart:267-285`

- [ ] **Step 1: Wrap SegmentedButton in SizedBox with explicit width**

Find the SegmentedButton widget (around line 267). It currently looks like:

```dart
SegmentedButton<String>(
  segments: const <ButtonSegment<String>>[
    ButtonSegment<String>(
      value: 'expense',
      label: Text('지출'), // Expense
    ),
    ButtonSegment<String>(
      value: 'income',
      label: Text('수입'), // Income
    ),
  ],
  selected: <String>{_transactionType},
  onSelectionChanged: (Set<String> newSelection) {
    setState(() {
      _transactionType = newSelection.first;
      _selectedCategory = null;
    });
  },
),
```

Wrap it in a SizedBox with full width:

```dart
SizedBox(
  width: double.infinity,
  child: SegmentedButton<String>(
    segments: const <ButtonSegment<String>>[
      ButtonSegment<String>(
        value: 'expense',
        label: Text('지출'), // Expense
      ),
      ButtonSegment<String>(
        value: 'income',
        label: Text('수입'), // Income
      ),
    ],
    selected: <String>{_transactionType},
    onSelectionChanged: (Set<String> newSelection) {
      setState(() {
        _transactionType = newSelection.first;
        _selectedCategory = null;
      });
    },
  ),
),
```

- [ ] **Step 2: Verify the change**

```bash
cd flutter_app && flutter analyze lib/features/record/record_page.dart
```

Expected: No errors or warnings.

---

## Task 5: Test the changes in the app

**Files:**
- Test: Flutter app runtime (no file changes)

- [ ] **Step 1: Clean and rebuild the Flutter app**

```bash
cd flutter_app && flutter clean && flutter pub get
```

- [ ] **Step 2: Run the app on device/emulator**

```bash
flutter run -d R39M5000ZVH
```

(Replace R39M5000ZVH with your device ID if different)

- [ ] **Step 3: Test UserProfileButton visibility**

- Log in to the app
- Navigate to any authenticated page (Record, Calendar, Stats, AI)
- Look for the user avatar button in the top-right corner of AppBar
- Verify it's visible and clickable

- [ ] **Step 4: Test UserProfileSheet opening**

- Tap the avatar button
- Bottom sheet should slide up with smooth animation
- Verify it shows:
  - User avatar (or initials fallback)
  - User name prominently
  - User email below name
  - Red logout button
  - Close (X) button

- [ ] **Step 5: Test logout functionality**

- In the profile sheet, tap the logout button
- Should be redirected to login page
- Session should be cleared

- [ ] **Step 6: Test RecordPage SegmentedButton layout**

- Navigate to Record page (or tap "기록" in bottom nav)
- SegmentedButton should render horizontally immediately
- No vertical-to-horizontal snap on initial load
- Refresh app multiple times, buttons should always be horizontal

- [ ] **Step 7: Stop the app**

```bash
# Press Ctrl+C in the terminal
```

---

## Task 6: Commit all changes

**Files:**
- Created: `flutter_app/lib/shared/widgets/user_profile_sheet.dart`
- Created: `flutter_app/lib/shared/widgets/user_profile_button.dart`
- Modified: `flutter_app/lib/shared/widgets/bottom_nav_shell.dart`
- Modified: `flutter_app/lib/features/record/record_page.dart`

- [ ] **Step 1: Check git status**

```bash
git status
```

Expected: Shows the 4 files listed above (2 new, 2 modified)

- [ ] **Step 2: Stage all changes**

```bash
git add flutter_app/lib/shared/widgets/user_profile_sheet.dart flutter_app/lib/shared/widgets/user_profile_button.dart flutter_app/lib/shared/widgets/bottom_nav_shell.dart flutter_app/lib/features/record/record_page.dart
```

- [ ] **Step 3: Create the commit**

```bash
git commit -m "feat: add user profile sheet and logout, fix recordpage segmented button layout

- Create UserProfileSheet widget displaying user avatar, name, email
- Create UserProfileButton widget for avatar trigger in AppBar
- Integrate UserProfileButton into BottomNavShell AppBar
- User profile shows name, email, avatar from Supabase session
- Add logout button in profile sheet for sign out
- Fix RecordPage SegmentedButton vertical-to-horizontal snap by wrapping in SizedBox with full width

Co-Authored-By: Claude Haiku 4.5 <noreply@anthropic.com>"
```

- [ ] **Step 4: Verify the commit**

```bash
git log --oneline -1
```

Expected: Shows the new commit message

---

## Summary

This plan implements:

1. ✅ **UserProfileSheet** — Bottom sheet displaying user profile info and logout button
2. ✅ **UserProfileButton** — Avatar button trigger that opens the profile sheet
3. ✅ **BottomNavShell integration** — Adds AppBar with UserProfileButton to all authenticated pages
4. ✅ **RecordPage layout fix** — Wraps SegmentedButton in SizedBox for immediate horizontal rendering
5. ✅ **Testing** — Verification of all functionality in the running app
6. ✅ **Commit** — Final git commit with all changes

**Expected outcome:** User can tap their avatar in the top-right AppBar, see their profile info, and logout. RecordPage SegmentedButton renders horizontally immediately with no snap.
