import 'package:flutter/material.dart';

/// Departure / Arrival clock labels for routes (Firestore String shape).
class RouteClockTime {
  RouteClockTime._();

  /// Parses labels like "07:30 AM" / "7:30 am"; null if unknown.
  static TimeOfDay? parse(String raw) {
    final s = raw.trim();
    if (s.isEmpty) return null;
    final m = RegExp(
      r'^(\d{1,2}):(\d{2})\s*(AM|PM)?$',
      caseSensitive: false,
    ).firstMatch(s);
    if (m == null) return null;
    var hour = int.tryParse(m.group(1)!);
    final minute = int.tryParse(m.group(2)!);
    if (hour == null || minute == null) return null;
    if (minute < 0 || minute > 59) return null;
    final period = m.group(3)?.toUpperCase();
    if (period != null) {
      if (hour < 1 || hour > 12) return null;
      if (period == 'AM') {
        if (hour == 12) hour = 0;
      } else if (hour != 12) {
        hour += 12;
      }
    } else if (hour < 0 || hour > 23) {
      return null;
    }
    return TimeOfDay(hour: hour, minute: minute);
  }

  /// Matches existing Firestore / seed shape, e.g. "07:30 AM".
  static String format(TimeOfDay time) {
    final hour12 = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final h = hour12.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$h:$m $period';
  }

  /// True when arrival is strictly earlier than departure (same calendar day).
  static bool arrivalBeforeDeparture(String departure, String arrival) {
    final dep = parse(departure);
    final arr = parse(arrival);
    if (dep == null || arr == null) return false;
    final depMins = dep.hour * 60 + dep.minute;
    final arrMins = arr.hour * 60 + arr.minute;
    return arrMins < depMins;
  }
}
