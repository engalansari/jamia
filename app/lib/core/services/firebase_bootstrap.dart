import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../firebase/firebase_options.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await FirebaseBootstrap.initialize();
}

class FirebaseBootstrap {
  const FirebaseBootstrap._();

  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;

    final options = DefaultFirebaseOptions.currentPlatformOrNull;
    if (options == null) {
      await Firebase.initializeApp();
    } else {
      await Firebase.initializeApp(options: options);
    }

    if (!kIsWeb) {
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    }
    _initialized = true;
  }
}
