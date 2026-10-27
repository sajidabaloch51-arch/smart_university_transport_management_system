import 'package:flutter/material.dart';

/// Shared feedback categories — student dropdown and admin filters must match.
class FeedbackCategories {
  FeedbackCategories._();

  static const String busDelay = 'Bus Delay';
  static const String driverBehavior = 'Driver Behavior';
  static const String cleanliness = 'Cleanliness';
  static const String routeIssue = 'Route Issue';
  static const String safety = 'Safety';
  static const String other = 'Other';

  static const List<String> all = [
    busDelay,
    driverBehavior,
    cleanliness,
    routeIssue,
    safety,
    other,
  ];

  static IconData iconFor(String category) {
    switch (category) {
      case busDelay:
        return Icons.schedule;
      case driverBehavior:
        return Icons.person;
      case cleanliness:
        return Icons.cleaning_services;
      case routeIssue:
        return Icons.alt_route;
      case safety:
        return Icons.health_and_safety;
      default:
        return Icons.feedback_outlined;
    }
  }

  static Color colorFor(String category) {
    switch (category) {
      case busDelay:
        return const Color(0xFFEA580C);
      case driverBehavior:
        return const Color(0xFF2563EB);
      case cleanliness:
        return const Color(0xFF059669);
      case routeIssue:
        return const Color(0xFF7C3AED);
      case safety:
        return const Color(0xFFDC2626);
      default:
        return const Color(0xFF64748B);
    }
  }
}

class FeedbackStatuses {
  FeedbackStatuses._();

  static const String newStatus = 'new';
  static const String reviewed = 'reviewed';
  static const String resolved = 'resolved';

  static const List<String> all = [newStatus, reviewed, resolved];

  static String label(String status) {
    switch (status) {
      case reviewed:
        return 'Reviewed';
      case resolved:
        return 'Resolved';
      default:
        return 'New';
    }
  }

  static Color colorFor(String status) {
    switch (status) {
      case reviewed:
        return const Color(0xFF2563EB);
      case resolved:
        return const Color(0xFF059669);
      default:
        return const Color(0xFFEA580C);
    }
  }
}
