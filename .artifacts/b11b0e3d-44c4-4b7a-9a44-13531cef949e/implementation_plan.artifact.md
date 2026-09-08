# SUTMS System Enhancements Plan

This plan outlines the comprehensive updates for Authentication, Dashboards (Student & Admin), Permissions, and UI/UX improvements across the University of Gwadar Smart Transport System (SUTMS).

## Proposed Changes

### 1. Authentication & Validation

#### [MODIFY] [student_registration_screen.dart](file:///C:/Users/Rustam Meerkhani/AndroidStudioProjects/MyApplication/lib/screens/auth/student_registration_screen.dart)
- Verify and ensure required fields are present: **Full Name**, **Registration Number**, **Phone Number**, and **Route Address**.
- Ensure `AppValidators.validatePassword` is applied to the password field for strong validation (8+ chars, upper, lower, digit, special).
- Update error messages to be descriptive and user-friendly.

#### [MODIFY] [login_screen.dart](file:///C:/Users/Rustam Meerkhani/AndroidStudioProjects/MyApplication/lib/screens/auth/login_screen.dart)
- Fully integrate "Remember Me" logic:
    - Save user credentials and login state to `SharedPreferences` upon successful login if checked.

#### [MODIFY] [splash_screen.dart](file:///C:/Users/Rustam Meerkhani/AndroidStudioProjects/MyApplication/lib/screens/auth/splash_screen.dart)
- Implement auto-login check:
    - On app start, check `SharedPreferences` for an active session.
    - Navigate directly to the appropriate dashboard (Student/Admin/Driver) if a session exists.

---

### 2. Student Dashboard & Profile

#### [MODIFY] [student_dashboard.dart](file:///C:/Users/Rustam Meerkhani/AndroidStudioProjects/MyApplication/lib/screens/student/student_dashboard.dart)
- **UI Refresh:** Set background to a clean white (`AppColors.backgroundLight`).
- **Readability:** Use white text for AppBar and Dashboard Cards (existing), and high-contrast dark text for page labels.
- **Compact Layout:** Change `childAspectRatio` from `1.5` to `2.2` in the `GridView` for a more professional look.
- **Feedback:** Add a "Submit Feedback" `DashboardCard` navigating to `/feedback`.

#### [MODIFY] [profile_screen.dart](file:///C:/Users/Rustam Meerkhani/AndroidStudioProjects/MyApplication/lib/screens/student/profile_screen.dart)
- **Permissions:** Add an "Edit Profile" button/screen to allow students to update their own details (Phone, Address, etc.).

---

### 3. Admin Dashboard & Management

#### [MODIFY] [admin_dashboard.dart](file:///C:/Users/Rustam Meerkhani/AndroidStudioProjects/MyApplication/lib/screens/admin/admin_dashboard.dart)
- **UI Refresh:** Set background to clean white.
- **Navigation:** Ensure "Manage Students", "Manage Notices", and "View Feedback" are prominent and easily accessible.

#### [MODIFY] [manage_students_screen.dart](file:///C:/Users/Rustam Meerkhani/AndroidStudioProjects/MyApplication/lib/screens/admin/manage_students_screen.dart)
- **CRUD Operations:** Verify that "Add", "Edit", and "Delete" actions are fully functional for student records.

---

### 4. General UI/UX Improvements

#### [Global] Theme Updates
- Update `AppColors` or main `ThemeData` to ensure a consistent white background theme across all dashboards.
- Ensure all forms use `CustomTextField` with proper validation and error message display.

## Verification Plan

### Automated Tests
- Run existing unit tests for `AppValidators`.

### Manual Verification
- **Auth:** Test registration with weak passwords, verify error messages. Test "Remember Me" by restarting the app.
- **Student Dashboard:** Verify white background, compact card size, and navigation to Feedback.
- **Student Profile:** Verify "Edit Profile" functionality and data persistence.
- **Admin Dashboard:** Verify CRUD operations for student records and notice posting.
- **UI:** Visual inspection of responsiveness and design consistency.
