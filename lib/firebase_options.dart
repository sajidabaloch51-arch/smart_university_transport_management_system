// File generated from android/app/google-services.json for project sutms-uog.
// Ignore for platform-specific FlutterFire CLI regeneration when available.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDtouw9raLD-fu9yAotY71sksxSEG-8jTg',
    appId: '1:100031780267:web:5074df095acfc7be296eee',
    messagingSenderId: '100031780267',
    projectId: 'sutms-uog',
    authDomain: 'sutms-uog.firebaseapp.com',
    storageBucket: 'sutms-uog.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDtouw9raLD-fu9yAotY71sksxSEG-8jTg',
    appId: '1:100031780267:android:5074df095acfc7be296eee',
    messagingSenderId: '100031780267',
    projectId: 'sutms-uog',
    storageBucket: 'sutms-uog.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDtouw9raLD-fu9yAotY71sksxSEG-8jTg',
    appId: '1:100031780267:ios:5074df095acfc7be296eee',
    messagingSenderId: '100031780267',
    projectId: 'sutms-uog',
    storageBucket: 'sutms-uog.firebasestorage.app',
    iosBundleId: 'com.example.sutms',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyDtouw9raLD-fu9yAotY71sksxSEG-8jTg',
    appId: '1:100031780267:ios:5074df095acfc7be296eee',
    messagingSenderId: '100031780267',
    projectId: 'sutms-uog',
    storageBucket: 'sutms-uog.firebasestorage.app',
    iosBundleId: 'com.example.sutms',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyDtouw9raLD-fu9yAotY71sksxSEG-8jTg',
    appId: '1:100031780267:web:5074df095acfc7be296eee',
    messagingSenderId: '100031780267',
    projectId: 'sutms-uog',
    authDomain: 'sutms-uog.firebaseapp.com',
    storageBucket: 'sutms-uog.firebasestorage.app',
  );
}
