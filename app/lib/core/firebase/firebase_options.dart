import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class DefaultFirebaseOptions {
  const DefaultFirebaseOptions._();

  static FirebaseOptions? get currentPlatformOrNull {
    if (kIsWeb) return web;

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return null;
      case TargetPlatform.linux:
      case TargetPlatform.windows:
      case TargetPlatform.fuchsia:
        return null;
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDQ9PjUK4msDE2x_WTH2Fo1Ua-y9QC4gzM',
    appId: '1:1025246578239:android:da86fafce2922cee78da8a',
    messagingSenderId: '1025246578239',
    projectId: 'jamiaq8',
    storageBucket: 'jamiaq8.firebasestorage.app',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBG2AvkA9uORu2U1KSvle5698BLDmCdAVI',
    appId: '1:1025246578239:web:a6edc34d9e4f869278da8a',
    messagingSenderId: '1025246578239',
    projectId: 'jamiaq8',
    authDomain: 'jamiaq8.firebaseapp.com',
    storageBucket: 'jamiaq8.firebasestorage.app',
    measurementId: 'G-DX2P1W9QN2',
  );
}
