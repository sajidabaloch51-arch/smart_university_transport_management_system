# Implementation Plan - Student Transport Management System Enhancements

This plan outlines the changes to improve student registration, login, route management, and admin verification in the SUTMS project.

## User Review Required

> [!IMPORTANT]
> The Student Portal entry will now have a dedicated screen for choosing between Login and Registration, as requested.
> Student login will be blocked until the Admin approves the registration request.

## Proposed Changes

### 1. Core & Widgets

#### [MODIFY] [app_validators.dart](file:///C:/Users/Rustam Meerkhani/AndroidStudioProjects/MyApplication/lib/core/validators/app_validators.dart)
- Enhance `validateEmail` with a stricter regex.
- Ensure `validatePassword` meets all strength requirements mentioned in the task.

#### [MODIFY] [custom_textfield.dart](file:///C:/Users/Rustam Meerkhani/AndroidStudioProjects/MyApplication/lib/widgets/custom_textfield.dart)
- Add a `showVisibilityToggle` property.
- Implement a suffix icon to toggle password visibility.
- Set default `autovalidateMode` to `onUserInteraction` to fulfill Requirement 8.

---

### 2. Models

#### [MODIFY] [student_model.dart](file:///C:/Users/Rustam Meerkhani/AndroidStudioProjects/MyApplication/lib/models/student_model.dart)
- Add `assignedRouteId` and `assignedRouteName` fields.
- Update `fromMap` and `toMap` methods.

---

### 3. Authentication & Registration

#### [NEW] [student_portal_entry_screen.dart](file:///C:/Users/Rustam Meerkhani/AndroidStudioProjects/MyApplication/lib/screens/auth/student_portal_entry_screen.dart)
- A new screen providing two large, clear options: **Student Login** and **Student Registration**.

#### [MODIFY] [role_selection_screen.dart](file:///C:/Users/Rustam Meerkhani/AndroidStudioProjects/MyApplication/lib/screens/shared/role_selection_screen.dart)
- Update the "Student" card to navigate to the new `StudentPortalEntryScreen`.

#### [MODIFY] [student_registration_screen.dart](file:///C:/Users/Rustam Meerkhani/AndroidStudioProjects/MyApplication/lib/screens/auth/student_registration_screen.dart)
- Add a Department dropdown with a list of available departments.
- Add a Route dropdown to allow students to select a valid route during registration.
- Use the updated `CustomTextField` for password with visibility toggle.
- Ensure email validation is applied.

#### [MODIFY] [login_screen.dart](file:///C:/Users/Rustam Meerkhani/AndroidStudioProjects/MyApplication/lib/screens/shared/login_screen.dart)
- Use the updated `CustomTextField` for password with visibility toggle.
- Add a check for `verificationStatus` before allowing a student to log in. Show a clear message if the status is `pending` or `rejected`.

---

### 4. Student Portal Enhancements

#### [MODIFY] [student_dashboard.dart](file:///C:/Users/Rustam Meerkhani/AndroidStudioProjects/MyApplication/lib/screens/student/student_dashboard.dart)
- Add a "My Assigned Route" section showing:
    - Route Name/Identifier (e.g., Route A).
    - Assigned Driver Information (fetched via `DriverProvider`).
- Improve the UI layout to clearly display this information.

#### [MODIFY] [schedule_screen.dart](file:///C:/Users/Rustam Meerkhani/AndroidStudioProjects/MyApplication/lib/screens/student/schedule_screen.dart)
- Filter or highlight the schedule corresponding to the student's assigned route.

---

### 5. Routing Configuration

#### [MODIFY] [app_router.dart](file:///C:/Users/Rustam Meerkhani/AndroidStudioProjects/MyApplication/lib/config/app_router.dart)
- Register the new `StudentPortalEntryScreen` route.

## Verification Plan

### Automated Tests
- Run existing unit tests for models and providers.
- I will verify the build succeeds after these changes.

### Manual Verification
1. **Registration Flow**:
   - Open App -> Role Selection -> Student -> Register.
   - Enter invalid email/password and verify error messages appear only after interaction.
   - Select Department and Route from dropdowns.
   - Submit and verify success message.
2. **Admin Flow**:
   - Login as Admin.
   - Go to Student Verification.
   - Approve the new student request.
3. **Login Flow**:
   - Login as Student.
   - Verify that login is blocked if status is still pending.
   - Verify that login works after approval.
   - Test password visibility toggle.
4. **Dashboard Verification**:
   - Check if assigned Route and Driver are displayed correctly on the dashboard.
   - Check if the Schedule screen shows the correct route details.
