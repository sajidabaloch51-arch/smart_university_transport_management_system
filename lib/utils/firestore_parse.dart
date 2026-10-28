import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Null-safe / type-tolerant helpers for Firestore document fields.
class FirestoreParse {
  FirestoreParse._();

  static DateTime? asDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is int) {
      // Seconds vs millis heuristic.
      if (value > 9999999999) {
        return DateTime.fromMillisecondsSinceEpoch(value);
      }
      return DateTime.fromMillisecondsSinceEpoch(value * 1000);
    }
    if (value is double) {
      return asDateTime(value.round());
    }
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) return null;
      return DateTime.tryParse(trimmed);
    }
    return null;
  }

  static DateTime asDateTimeOrNow(dynamic value) =>
      asDateTime(value) ?? DateTime.now();

  static String asString(dynamic value, [String fallback = '']) {
    if (value == null) return fallback;
    if (value is String) return value;
    return value.toString();
  }

  static int? asInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is String) return int.tryParse(value.trim());
    return null;
  }

  static bool asBool(dynamic value, {bool fallback = false}) {
    if (value == null) return fallback;
    if (value is bool) return value;
    if (value is num) return value != 0;
    final s = value.toString().trim().toLowerCase();
    if (s == 'true' || s == '1' || s == 'yes') return true;
    if (s == 'false' || s == '0' || s == 'no') return false;
    return fallback;
  }

  static List<String> asStringList(
    dynamic value, {
    List<String> fallback = const [],
  }) {
    if (value == null) return fallback;
    if (value is! List) return fallback;
    final out = <String>[];
    for (final item in value) {
      if (item == null) continue;
      out.add(item.toString());
    }
    return out.isEmpty ? fallback : out;
  }

  /// Maps docs one-by-one; skips bad documents instead of failing the list.
  static List<T> mapDocs<T>(
    Iterable<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    T? Function(Map<String, dynamic> data, String id) convert, {
    String label = 'docs',
  }) {
    final out = <T>[];
    for (final doc in docs) {
      try {
        final item = convert(doc.data(), doc.id);
        if (item != null) out.add(item);
      } catch (e, st) {
        debugPrint(
          '⚠️ Skipping bad $label doc id=${doc.id}: $e\n$st',
        );
      }
    }
    return out;
  }
}
