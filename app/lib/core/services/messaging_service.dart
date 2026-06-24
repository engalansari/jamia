import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../models/app_user.dart';

const _webPushVapidKey = String.fromEnvironment(
  'FIREBASE_WEB_PUSH_VAPID_KEY',
  defaultValue:
      'BLWEiFXYY-eFCjok0uOa5-xOk_eiZGhcy_0f4Fvx9cz3pCZMp9RWHdL-yKxqhD2NqZjgKmxUNqFTmxdSy3g8CeQ',
);

enum MessagingRegistrationResult {
  registered,
  missingWebPushKey,
  permissionDenied,
  noToken,
}

class NotificationPreferences {
  const NotificationPreferences({
    this.requestCreated = true,
    this.shoppingStarted = true,
  });

  final bool requestCreated;
  final bool shoppingStarted;

  factory NotificationPreferences.fromJson(Map<String, dynamic>? json) {
    return NotificationPreferences(
      requestCreated: json?['requestCreated'] as bool? ?? true,
      shoppingStarted: json?['shoppingStarted'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'requestCreated': requestCreated,
      'shoppingStarted': shoppingStarted,
      'updatedAt': DateTime.now().toIso8601String(),
    };
  }

  NotificationPreferences copyWith({
    bool? requestCreated,
    bool? shoppingStarted,
  }) {
    return NotificationPreferences(
      requestCreated: requestCreated ?? this.requestCreated,
      shoppingStarted: shoppingStarted ?? this.shoppingStarted,
    );
  }
}

class MessagingService {
  MessagingService({FirebaseMessaging? messaging, FirebaseFirestore? firestore})
    : _messaging = messaging ?? FirebaseMessaging.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseMessaging _messaging;
  final FirebaseFirestore _firestore;

  Stream<RemoteMessage> get foregroundMessages => FirebaseMessaging.onMessage;

  DocumentReference<Map<String, dynamic>> _preferencesDoc(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('settings')
        .doc('notificationPreferences');
  }

  Stream<NotificationPreferences> watchNotificationPreferences(String userId) {
    return _preferencesDoc(userId).snapshots().map(
      (snapshot) => NotificationPreferences.fromJson(snapshot.data()),
    );
  }

  Future<void> saveNotificationPreferences(
    String userId,
    NotificationPreferences preferences,
  ) {
    return _preferencesDoc(
      userId,
    ).set(preferences.toJson(), SetOptions(merge: true));
  }

  Future<NotificationSettings> requestPermission() {
    return _messaging.requestPermission(alert: true, badge: true, sound: true);
  }

  Future<String?> getToken() {
    return _messaging.getToken(
      vapidKey: kIsWeb ? _webPushVapidKey : null,
      serviceWorkerScriptPath: kIsWeb ? 'firebase-messaging-sw.js' : null,
    );
  }

  Future<MessagingRegistrationResult> registerDevice(AppUser user) async {
    if (kIsWeb && _webPushVapidKey.isEmpty) {
      return MessagingRegistrationResult.missingWebPushKey;
    }
    final settings = await requestPermission();
    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      return MessagingRegistrationResult.permissionDenied;
    }
    final token = await getToken();
    if (token == null || token.isEmpty) {
      return MessagingRegistrationResult.noToken;
    }

    await _firestore
        .collection('users')
        .doc(user.userId)
        .collection('pushTokens')
        .doc(Uri.encodeComponent(token))
        .set({
          'token': token,
          'platform': kIsWeb ? 'web' : defaultTargetPlatform.name,
          'userId': user.userId,
          'updatedAt': DateTime.now().toIso8601String(),
        }, SetOptions(merge: true));
    return MessagingRegistrationResult.registered;
  }
}
