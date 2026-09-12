# Authentication & Validation Implementation Plan

This plan outlines the changes required to implement strong password validation, update the Sign Up page with mandatory fields, and enable "Remember Me" functionality.

## User Review Required

> [!IMPORTANT]
> - **Password Strength**: The new validation requires at least one uppercase letter, one lowercase letter, one digit, and one special character, with a minimum of 8 characters.
> - **Remember Me**: This will be implemented using `shared_preferences` to persist a flag. If enabled, the user will bypass the login screen on subsequent app launches if their Firebase session is still active.

## Proposed Changes

### [Dependencies]

#### [MODIFY] [pubspec.yaml](file:///C:/Users/PC/AndroidStudioProjects/smart university transport management system/pubspec.yaml)
- Add `shared_preferences: ^2.2.3` to the dependencies.

---

### [Core & Shared]

#### [MODIFY] [app_validators.dart](file:///C:/Users/PC/AndroidStudioProjects/smart university transport management system/lib/core/validators/app_validators.dart)
- Update `validatePassword` to implement strong password rules using Regex.

---

### [Models]

#### [MODIFY] [student_model.dart](file:///C:/Users/PC/AndroidStudioProjects/smart university transport management system/lib/models/student_model.dart)
- Add `routeAddress` field to the class, `fromMap`, and `toMap` methods.

---

### [Authentication Screens]

#### [MODIFY] [student_registration_screen.dart](file:///C:/Users/PC/AndroidStudioProjects/smart university transport management system/lib/screens/auth/student_registration_screen.dart)
- Add `_phoneController` and `_routeController` to the state.
- Update the UI to include "Phone Number" and "Route Address" input fields.
- Ensure all required fields (Full Name, Registration Number, Phone Number, Route Address) use `AppValidators.validateRequired`.

#### [MODIFY] [login_screen.dart](file:///C:/Users/PC/AndroidStudioProjects/smart university transport management system/lib/screens/shared/login_screen.dart)
- Add `_rememberMe` boolean state and a `CheckboxListTile` (or `Row` with `Checkbox`) to the UI.
- Use `shared_preferences` to save the `rememberMe` flag upon successful login.

---

### [App Lifecycle]

#### [MODIFY] [splash_screen.dart](file:///C:/Users/PC/AndroidStudioProjects/smart university transport management system/lib/screens/shared/splash_screen.dart)
- Update `_navigateToNext` to:
    1. Initialize `shared_preferences`.
    2. Check the `rememberMe` flag.
    3. Check `FirebaseAuth.instance.currentUser`.
    4. Redirect to the appropriate Dashboard if both are valid, otherwise go to `/onboarding` or `/role-selection`.

## Verification Plan

### Automated Tests
- Run unit tests for `AppValidators.validatePassword` with various test cases (weak vs strong).
- Run `flutter test` to ensure no regressions in routing logic.

### Manual Verification
1. **Password Validation**: Try to register with a simple password (e.g., "password123") and verify it fails with specific error messages.
2. **Sign Up Page**: Verify all new fields (Phone, Route Address) are visible and mandatory.
3. **Remember Me**:
    - Log in with "Remember Me" checked.
    - Close the app and relaunch.
    - Verify it skips the login screen and lands on the dashboard.
    - Log out, relaunch, and verify it stays on the login/onboarding screen.
