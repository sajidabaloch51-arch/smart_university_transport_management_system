import 'dart:js_interop';

import 'package:flutter/foundation.dart';

@JS('firebase_core.getApp')
external JSAny _getApp();

@JS('firebase_firestore.initializeFirestore')
external JSAny _initializeFirestore(JSAny app, JSAny settings);

@JS('firebase_firestore.memoryLocalCache')
external JSAny _memoryLocalCache();

/// Anonymous JS settings so properties bind correctly on the modular SDK.
@anonymous
@JS()
@staticInterop
abstract class _FsWebSettings {
  external factory _FsWebSettings({
    JSBoolean? experimentalForceLongPolling,
    JSAny? localCache,
  });
}

/// Initialize the JS Firestore SDK with forced long-polling before FlutterFire
/// touches it. WebChannel hangs behind many proxies/antivirus setups; REST
/// still works (probe: _meta/health). Long-polling avoids the infinite spinner.
///
/// Must call [initializeFirestore] (never getFirestore first) so defaults
/// without long-polling are not applied.
void configureWebFirestore() {
  try {
    final settings = _FsWebSettings(
      experimentalForceLongPolling: true.toJS,
      localCache: _memoryLocalCache(),
    );
    _initializeFirestore(_getApp(), settings as JSAny);
    debugPrint('🔥 Firestore web: force long-polling + memory cache');
  } catch (e) {
    // Hot restart: already initialized — keep existing instance.
    debugPrint('🔥 Firestore web long-polling setup skipped: $e');
  }
}
