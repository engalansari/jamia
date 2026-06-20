import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../models/app_user.dart';

class MessagingService {
  MessagingService({FirebaseMessaging? messaging, FirebaseFirestore? firestore})
    : _messaging = messaging ?? FirebaseMessaging.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseMessaging _messaging;
  final FirebaseFirestore _firestore;

  Stream<RemoteMessage> get foregroundMessages => FirebaseMessaging.onMessage;

  Future<NotificationSettings> requestPermission() {
    return _messaging.requestPermission(alert: true, badge: true, sound: true);
  }

  Future<String?> getToken() => _messaging.getToken();

  Future<void> registerDevice(AppUser user) async {
    if (kIsWeb) return;
    await requestPermission();
    final token = await getToken();
    if (token == null || token.isEmpty) return;
    await _firestore.collection('users').doc(user.userId).set({
      'fcmTokens': FieldValue.arrayUnion([token]),
      'lastFcmTokenUpdatedAt': DateTime.now().toIso8601String(),
    }, SetOptions(merge: true));
  }
}
