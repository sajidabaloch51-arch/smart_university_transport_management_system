import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../screens/shared/splash_screen.dart';
import '../screens/shared/onboarding_screen.dart';
import '../screens/shared/login_screen.dart';
import '../screens/shared/role_selection_screen.dart';
import '../screens/shared/forgot_password_screen.dart';
import '../screens/shared/personal_info_screen.dart';
import '../screens/student/student_dashboard.dart';
import '../screens/student/student_home_screen.dart';
import '../screens/student/route_screen.dart';
import '../screens/student/route_detail_screen.dart';
import '../screens/student/live_map_screen.dart';
import '../screens/student/notice_screen.dart';
import '../screens/student/notice_detail_screen.dart';
import '../screens/student/feedback_screen.dart';
import '../screens/student/profile_screen.dart';
import '../screens/student/schedule_screen.dart';
import '../screens/driver/driver_dashboard.dart';
import '../screens/driver/driver_profile_screen.dart';
import '../screens/driver/driver_notices_screen.dart';
import '../screens/driver/driver_route_screen.dart';
import '../screens/driver/edit_driver_profile_screen.dart';

// Admin Screens
import '../screens/admin/admin_dashboard.dart';
import '../screens/admin/manage_students_screen.dart';
import '../screens/admin/add_edit_student_screen.dart';
import '../screens/admin/manage_drivers_screen.dart';
import '../screens/admin/add_edit_driver_screen.dart';
import '../screens/admin/manage_routes_screen.dart';
import '../screens/admin/add_edit_route_screen.dart';
import '../screens/admin/manage_buses_screen.dart';
import '../screens/admin/add_edit_bus_screen.dart';
import '../screens/admin/manage_schedule_screen.dart';
import '../screens/admin/add_edit_schedule_screen.dart';
import '../screens/admin/manage_notices_screen.dart';
import '../screens/admin/post_notice_screen.dart';
import '../screens/admin/feedback_screen.dart' as admin_feedback;
import '../screens/admin/admin_profile_screen.dart';
import '../screens/admin/system_reports_screen.dart';
import '../screens/admin/student_details_screen.dart';

// Models
import '../models/student_model.dart';
import '../models/driver_model.dart';
import '../models/bus_model.dart';
import '../models/route_model.dart';
import '../models/schedule_model.dart';
import '../models/notice_model.dart';

import '../screens/auth/student_registration_screen.dart';
import '../screens/auth/driver_registration_screen.dart';
import '../screens/auth/admin_registration_screen.dart';

import '../screens/admin/student_verification_screen.dart';
import '../screens/admin/verify_student_details_screen.dart';

import '../screens/auth/student_portal_entry_screen.dart';

class AppRouter {
  static final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
      GoRoute(path: '/onboarding', builder: (context, state) => const OnboardingScreen()),
      GoRoute(path: '/role-selection', builder: (context, state) => const RoleSelectionScreen()),
      GoRoute(path: '/student-portal-entry', builder: (context, state) => const StudentPortalEntryScreen()),
      GoRoute(path: '/login', builder: (context, state) => LoginScreen(role: state.extra as String?)),
      GoRoute(path: '/forgot-password', builder: (context, state) => const ForgotPasswordScreen()),
      
      // Registration Routes
      GoRoute(path: '/student-registration', builder: (context, state) => const StudentRegistrationScreen()),
      GoRoute(path: '/driver-registration', builder: (context, state) => const DriverRegistrationScreen()),
      GoRoute(path: '/admin-registration', builder: (context, state) => const AdminRegistrationScreen()),
      
      // Admin Action Routes
      GoRoute(path: '/add-edit-student', builder: (context, state) {
        final student = state.extra is StudentModel ? state.extra as StudentModel : null;
        return AddEditStudentScreen(student: student);
      }),
      GoRoute(path: '/add-edit-driver', builder: (context, state) {
        final driver = state.extra is DriverModel ? state.extra as DriverModel : null;
        return AddEditDriverScreen(driver: driver);
      }),
      GoRoute(path: '/add-edit-route', builder: (context, state) {
        final route = state.extra is RouteModel ? state.extra as RouteModel : null;
        return AddEditRouteScreen(route: route);
      }),
      GoRoute(path: '/add-edit-bus', builder: (context, state) {
        final bus = state.extra is BusModel ? state.extra as BusModel : null;
        return AddEditBusScreen(bus: bus);
      }),
      GoRoute(path: '/add-edit-schedule', builder: (context, state) {
        final schedule = state.extra is ScheduleModel ? state.extra as ScheduleModel : null;
        return AddEditScheduleScreen(schedule: schedule);
      }),
      GoRoute(path: '/add-edit-notice', builder: (context, state) {
        final notice = state.extra is NoticeModel ? state.extra as NoticeModel : null;
        return PostNoticeScreen(notice: notice);
      }),
      
      // Student Routes
      GoRoute(path: '/student-dashboard', builder: (context, state) => const StudentDashboard()),
      GoRoute(path: '/student-home', builder: (context, state) => const StudentHomeScreen()),
      GoRoute(path: '/student-routes', builder: (context, state) => const RouteScreen()),
      GoRoute(path: '/route-detail/:id', builder: (context, state) => RouteDetailScreen(routeId: state.pathParameters['id'] ?? 'A')),
      GoRoute(path: '/live-tracking', builder: (context, state) => const LiveMapScreen()),
      GoRoute(path: '/notices', builder: (context, state) => const NoticeScreen()),
      GoRoute(path: '/notice-detail', builder: (context, state) {
        final notice = state.extra as NoticeModel?;
        if (notice == null) return const NoticeScreen();
        return NoticeDetailScreen(notice: notice);
      }),
      GoRoute(path: '/feedback', builder: (context, state) => const FeedbackScreen()),
      GoRoute(path: '/schedule', builder: (context, state) {
        final routeId = state.extra as String?;
        return ScheduleScreen(routeId: routeId);
      }),
      GoRoute(path: '/personal-info', builder: (context, state) => const PersonalInfoScreen()),
      
      // Driver Routes
      GoRoute(path: '/driver-dashboard', builder: (context, state) => const DriverDashboard()),
      GoRoute(path: '/driver-profile', builder: (context, state) => const DriverProfileScreen()),
      GoRoute(path: '/edit-driver-profile', builder: (context, state) => const EditDriverProfileScreen()),
      GoRoute(path: '/driver-notices', builder: (context, state) => const DriverNoticesScreen()),
      GoRoute(path: '/driver-route', builder: (context, state) => const DriverRouteScreen()),

      // Admin Routes
      GoRoute(path: '/admin-dashboard', builder: (context, state) => const AdminDashboard()),
      GoRoute(path: '/student-verification', builder: (context, state) => const StudentVerificationScreen()),
      GoRoute(path: '/verify-details', builder: (context, state) {
        final student = state.extra as StudentModel;
        return VerifyStudentDetailsScreen(student: student);
      }),
      GoRoute(path: '/manage-students', builder: (context, state) => const ManageStudentsScreen()),
      GoRoute(path: '/student-details', builder: (context, state) {
        final student = state.extra as StudentModel?;
        if (student == null) return const ManageStudentsScreen();
        return StudentDetailsScreen(student: student);
      }),
      GoRoute(path: '/manage-drivers', builder: (context, state) => const ManageDriversScreen()),
      GoRoute(path: '/add-edit-driver', builder: (context, state) => AddEditDriverScreen(driver: state.extra as DriverModel?)),
      GoRoute(path: '/manage-routes', builder: (context, state) => const ManageRoutesScreen()),
      GoRoute(path: '/add-edit-route', builder: (context, state) => AddEditRouteScreen(route: state.extra as RouteModel?)),
      GoRoute(path: '/manage-buses', builder: (context, state) => const ManageBusesScreen()),
      GoRoute(path: '/add-edit-bus', builder: (context, state) => AddEditBusScreen(bus: state.extra as BusModel?)),
      GoRoute(path: '/manage-schedules', builder: (context, state) => const ManageScheduleScreen()),
      GoRoute(path: '/add-edit-schedule', builder: (context, state) => AddEditScheduleScreen(schedule: state.extra as ScheduleModel?)),
      GoRoute(path: '/manage-notices', builder: (context, state) => const ManageNoticesScreen()),
      GoRoute(path: '/add-edit-notice', builder: (context, state) => PostNoticeScreen(notice: state.extra as NoticeModel?)),
      GoRoute(path: '/view-feedback', builder: (context, state) => const admin_feedback.FeedbackScreen()),
      GoRoute(path: '/system-reports', builder: (context, state) => const SystemReportsScreen()),
      GoRoute(path: '/admin-profile', builder: (context, state) => const AdminProfileScreen()),
    ],
  );
}
