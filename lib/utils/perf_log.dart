import 'package:flutter/foundation.dart';

/// Temporary timing helpers for screen / Firestore performance.
class PerfLog {
  PerfLog._();

  static final Map<String, Stopwatch> _watches = {};

  static void start(String key) {
    _watches[key] = Stopwatch()..start();
    debugPrint('⏱ START $key');
  }

  static void mark(String key, String label, {int? count}) {
    final w = _watches[key];
    final ms = w?.elapsedMilliseconds ?? -1;
    debugPrint(
      '⏱ MARK $key +${ms}ms $label${count != null ? ' count=$count' : ''}',
    );
  }

  static void end(String key, {String? label, int? count}) {
    final w = _watches.remove(key);
    if (w == null) return; // already ended — avoid builder spam
    debugPrint(
      '⏱ END $key ${w.elapsedMilliseconds}ms ${label ?? ''}'
      '${count != null ? ' count=$count' : ''}',
    );
  }
}
