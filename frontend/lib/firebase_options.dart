// Generated for project smartcar-290dd.
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
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDfyZV8hoCUCVnkNYK3kFOs75wWDyYE-xc',
    appId: '1:624089854276:web:2c72befb3c5511f81fa711',
    messagingSenderId: '624089854276',
    projectId: 'smartcar-290dd',
    authDomain: 'smartcar-290dd.firebaseapp.com',
    storageBucket: 'smartcar-290dd.firebasestorage.app',
    measurementId: 'G-RPVZ3NR0X0',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAz7gXLE-36hDpmwCPVJqXm2TkpR3Omc5c',
    appId: '1:624089854276:android:82a05cb4c4a46a6f1fa711',
    messagingSenderId: '624089854276',
    projectId: 'smartcar-290dd',
    storageBucket: 'smartcar-290dd.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDfyZV8hoCUCVnkNYK3kFOs75wWDyYE-xc',
    appId: '1:624089854276:ios:6db2c7ac568a18b11fa711',
    messagingSenderId: '624089854276',
    projectId: 'smartcar-290dd',
    storageBucket: 'smartcar-290dd.firebasestorage.app',
    iosBundleId: 'com.example.smartcar',
  );

  static const FirebaseOptions macos = ios;
}
