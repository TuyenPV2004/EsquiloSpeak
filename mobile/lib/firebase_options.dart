import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;

class DefaultFirebaseOptions {
  static const bool isDummyFirebaseConfig = true;

  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not configured for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'dummy_api_key',
    appId: '1:1234567890:android:abc123def456',
    messagingSenderId: '1234567890',
    projectId: 'esquilospeak-dev',
    storageBucket: 'esquilospeak-dev.appspot.com',
  );
}
