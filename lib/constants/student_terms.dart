import 'package:flutter/material.dart';

/// Version bump when terms text changes so users can be asked to re-accept.
const String kStudentTermsVersion = '1.0';

/// Soft accents (readable on light/dark when used as circle + icon).
class TermsAccent {
  static const Color blue = Color(0xFF1565C0);
  static const Color green = Color(0xFF2E7D32);
  static const Color teal = Color(0xFF00838F);
  static const Color orange = Color(0xFFEF6C00);
  static const Color red = Color(0xFFC62828);
  static const Color indigo = Color(0xFF3949AB);
  static const Color purple = Color(0xFF6A1B9A);
}

class TermsSection {
  final String title;
  final String body;
  final IconData icon;
  final Color accent;
  /// When non-empty, shown as bullet rows (same content, easier to scan).
  final List<String> bullets;

  const TermsSection({
    required this.title,
    required this.body,
    required this.icon,
    this.accent = TermsAccent.blue,
    this.bullets = const [],
  });
}

class TermsDocument {
  final String role;
  final String version;
  final String lastUpdated;
  final List<TermsSection> sections;

  const TermsDocument({
    required this.role,
    required this.version,
    required this.lastUpdated,
    required this.sections,
  });
}

const TermsDocument _studentTerms = TermsDocument(
  role: 'student',
  version: kStudentTermsVersion,
  lastUpdated: '27 October 2026',
  sections: [
    TermsSection(
      title: '1. Eligibility',
      icon: Icons.school_outlined,
      accent: TermsAccent.blue,
      body:
          'This service is for currently enrolled University of Gwadar students. '
          'You must register with your correct Roll No, department and contact details. '
          'Registrations that cannot be matched to university records are held for '
          'manual Admin verification and you can\'t log in until approved.',
    ),
    TermsSection(
      title: '2. Account Responsibility',
      icon: Icons.lock_outline,
      accent: TermsAccent.indigo,
      body:
          'Keep your password private. You are responsible for all activity under '
          'your account. Do not share your account or let others use your transport '
          'access. Report suspected misuse to the Transport Office immediately.',
    ),
    TermsSection(
      title: '3. Accurate Information',
      icon: Icons.fact_check_outlined,
      accent: TermsAccent.teal,
      body:
          'Details you provide (name, roll number, registration number, department, '
          'phone, email) must be true and up to date. False information can lead to '
          'rejection or suspension of your account.',
    ),
    TermsSection(
      title: '4. Transport Use',
      icon: Icons.directions_bus_outlined,
      accent: TermsAccent.green,
      body: 'Use university transport features responsibly:',
      bullets: [
        'Use the app to view bus routes, schedules, driver and bus details, and to select or cancel your route.',
        'You may select only routes available to students.',
        'Follow the schedule, board only at official stops, and respect the driver\'s and staff\'s instructions.',
      ],
    ),
    TermsSection(
      title: '5. Conduct on Buses',
      icon: Icons.groups_outlined,
      accent: TermsAccent.orange,
      body: 'Behaviour on university transport:',
      bullets: [
        'Behave respectfully toward drivers, staff and other students.',
        'Damage to buses, misuse of emergency or help features, harassment, or unsafe behavior may result in suspension from transport services and referral to university discipline.',
      ],
    ),
    TermsSection(
      title: '6. Route Selection and Cancellation',
      icon: Icons.alt_route,
      accent: TermsAccent.green,
      body:
          'Route selections and cancellations are subject to seat availability and '
          'Admin rules. The University may change, delay or cancel routes, timings and '
          'drivers for operational, weather or safety reasons, and the app will show '
          'notices where possible.',
    ),
    TermsSection(
      title: '7. Driver Contact',
      icon: Icons.phone_in_talk_outlined,
      accent: TermsAccent.teal,
      body:
          'Driver phone and message options are for transport-related matters only. '
          'Do not misuse, record or share drivers\' contact details.',
    ),
    TermsSection(
      title: '8. Privacy and Data',
      icon: Icons.privacy_tip_outlined,
      accent: TermsAccent.purple,
      body:
          'We collect your registration details and route activity only to provide '
          'and manage university transport. Your data is visible only to authorized '
          'university transport staff and Admins, is not sold to third parties, and is '
          'protected using secure authentication. If location features are used, they '
          'are only for transport tracking.',
    ),
    TermsSection(
      title: '9. Notices and Alerts',
      icon: Icons.notifications_active_outlined,
      accent: TermsAccent.blue,
      body:
          'You agree to receive transport notices and alerts in the app. Check them '
          'regularly.',
    ),
    TermsSection(
      title: '10. Suspension and Termination',
      icon: Icons.gavel_outlined,
      accent: TermsAccent.red,
      body:
          'The University may suspend or remove accounts for rule violations, false '
          'information, graduation or withdrawal from the university.',
    ),
    TermsSection(
      title: '11. Changes to Terms',
      icon: Icons.update,
      accent: TermsAccent.indigo,
      body:
          'These terms may be updated. Continued use of the app means you accept the '
          'updated terms.',
    ),
    TermsSection(
      title: '12. Contact',
      icon: Icons.support_agent,
      accent: TermsAccent.blue,
      body:
          'For help, use the Help Desk in the app or contact the University of '
          'Gwadar Transport Office.',
    ),
  ],
);

/// Returns role-specific terms. Student is implemented now; Driver/Admin later.
TermsDocument getTermsForRole(String role) {
  switch (role.toLowerCase()) {
    case 'student':
      return _studentTerms;
    // Driver and Admin terms can be added here later.
    default:
      return _studentTerms;
  }
}
