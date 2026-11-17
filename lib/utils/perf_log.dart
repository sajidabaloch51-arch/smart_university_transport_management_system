import 'package:flutter/foundation.dart';

/// Timing helpers for screen / Firestore performance and perf tests.
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

  /// Elapsed ms for an in-flight [key], or null if not started.
  static int? elapsedMs(String key) => _watches[key]?.elapsedMilliseconds;

  /// Runs [body] and returns wall time in milliseconds.
  static int measureSync(String key, void Function() body) {
    final sw = Stopwatch()..start();
    body();
    sw.stop();
    debugPrint('⏱ MEASURE $key ${sw.elapsedMilliseconds}ms');
    return sw.elapsedMilliseconds;
  }

  /// Async variant for I/O-bound checks (tests / screen loads).
  static Future<int> measureAsync(
    String key,
    Future<void> Function() body,
  ) async {
    final sw = Stopwatch()..start();
    await body();
    sw.stop();
    debugPrint('⏱ MEASURE $key ${sw.elapsedMilliseconds}ms');
    return sw.elapsedMilliseconds;
  }

  @visibleForTesting
  static void resetForTest() => _watches.clear();
}
