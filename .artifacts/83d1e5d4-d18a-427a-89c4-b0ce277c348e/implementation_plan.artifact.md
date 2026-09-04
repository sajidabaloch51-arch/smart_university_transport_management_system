# Authentication & Validation Enhancements

Implement strong password validation, update the Student Sign Up page with specific fields, and enable "Remember Me" functionality.

## User Review Required

> [!IMPORTANT]
> - Adding `shared_preferences` dependency to `pubspec.yaml`.
> - The strong password validation will require at least one uppercase letter, one lowercase letter, one number, and one special character.
> - "Remember Me" will persist the user's role and email to auto-fill or auto-login.

## Proposed Changes

### Core & Models

#### [MODIFY] [app_validators.dart](file:///C:/Users/Rustam%20Meerkhani/AndroidStudioProjects/MyApplication/lib/core/validators/app_validators.dart)
- Update `validatePassword` to use a RegEx for strong validation.

#### [MODIFY] [student_model.dart](file:///C:/Users/Rustam%20Meerkhani/AndroidStudioProjects/MyApplication/lib/models/student_model.dart)
- Add `routeAddress` field to `StudentModel`.

### Authentication UI

#### [MODIFY] [student_registration_screen.dart](file:///C:/Users/Rustam%20Meerkhani/AndroidStudioProjects/MyApplication/lib/screens/auth/student_registration_screen.dart)
- Update form to include: Full Name, Registration Number, Phone Number, and Route Address.
- Remove redundant fields like Father Name, Gender, DOB (if not requested). The user specifically asked for: Full Name, Registration Number, Phone Number, and Route Address. I will keep the existing ones but ensure the requested ones are present and mandatory.

#### [MODIFY] [login_screen.dart](file:///C:/Users/Rustam%20Meerkhani/AndroidStudioProjects/MyApplication/lib/screens/auth/login_screen.dart)
- Implement "Remember Me" logic using `shared_preferences`.
- Save credentials/state on successful login.

#### [MODIFY] [splash_screen.dart](file:///C:/Users/Rustam%20Meerkhani/AndroidStudioProjects/MyApplication/lib/screens/auth/splash_screen.dart)
- Check `shared_preferences` for "Remember Me" state.
- Auto-navigate to the correct dashboard if the user is remembered.

### Dependencies

#### [MODIFY] [pubspec.yaml](file:///C:/Users/Rustam%20Meerkhani/AndroidStudioProjects/MyApplication/pubspec.yaml)
- Add `shared_preferences: ^2.2.2`.

## Verification Plan

### Automated Tests
- N/A (Manual verification is more suitable for UI flow and persistence).

### Manual Verification
1. **Password Validation**: Try registering with a weak password (e.g., `12345678`) and verify it's rejected. Try with a strong one (e.g., `Password123!`) and verify it's accepted.
2. **Sign Up Fields**: Open the Student Registration screen and check if Full Name, Registration Number, Phone Number, and Route Address are present and validated.
3. **Remember Me**:
    - Log in with "Remember Me" checked.
    - Close the app and reopen.
    - Verify it auto-logs into the dashboard.
    - Log out, log in with "Remember Me" UNCHECKED.
    - Close the app and reopen.
    - Verify it stays on the login screen.
