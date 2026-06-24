import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/app_notification.dart';
import '../models/app_user.dart';
import '../models/model_enums.dart';
import '../models/shopping_request.dart';

class NotificationService {
  NotificationService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _notifications =>
      _firestore.collection('notifications');

  Stream<List<AppNotification>> watchNotificationsForUser(String userId) {
    return _notifications.limit(100).snapshots().map((snapshot) {
      final notifications = snapshot.docs
          .map(
            (doc) => AppNotification.fromJson({
              ...doc.data(),
              'notificationId': doc.id,
            }),
          )
          .where(
            (notification) =>
                notification.targetUsers.isEmpty ||
                notification.targetUsers.contains(userId),
          )
          .toList();
      notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return notifications;
    });
  }

  Future<void> createNotification({
    required String title,
    required String body,
    required NotificationType type,
    required String createdBy,
    List<String> targetUsers = const [],
    String? roundId,
    String? requestId,
    String? itemName,
  }) {
    final doc = _notifications.doc();
    final notification = AppNotification(
      notificationId: doc.id,
      title: title,
      body: body,
      type: type,
      createdBy: createdBy,
      createdAt: DateTime.now(),
      targetUsers: targetUsers,
      roundId: roundId,
      requestId: requestId,
      itemName: itemName,
    );
    return doc.set(notification.toJson());
  }

  Future<void> notifyRequestCreated({
    required AppUser user,
    required ShoppingRequest request,
  }) {
    return createNotification(
      title: '\u0637\u0644\u0628 \u062c\u062f\u064a\u062f',
      body: '${user.displayName} \u0623\u0636\u0627\u0641 ${request.itemName}',
      type: NotificationType.requestCreated,
      createdBy: user.userId,
      roundId: request.roundId,
      requestId: request.requestId,
      itemName: request.itemName,
    );
  }

  Future<void> notifyRequestUpdated({
    required AppUser user,
    required ShoppingRequest request,
  }) {
    return createNotification(
      title: '\u062a\u0639\u062f\u064a\u0644 \u0637\u0644\u0628',
      body: '${user.displayName} \u0639\u062f\u0644 ${request.itemName}',
      type: NotificationType.requestUpdated,
      createdBy: user.userId,
      roundId: request.roundId,
      requestId: request.requestId,
      itemName: request.itemName,
    );
  }

  Future<void> notifyRequestDeleted({
    required AppUser user,
    required ShoppingRequest request,
  }) {
    return createNotification(
      title: '\u062d\u0630\u0641 \u0637\u0644\u0628',
      body: '${user.displayName} \u062d\u0630\u0641 ${request.itemName}',
      type: NotificationType.requestDeleted,
      createdBy: user.userId,
      roundId: request.roundId,
      requestId: request.requestId,
      itemName: request.itemName,
    );
  }

  Future<void> notifyRequestPurchased({
    required AppUser user,
    required ShoppingRequest request,
  }) {
    return createNotification(
      title: '\u062a\u0645 \u0627\u0644\u0634\u0631\u0627\u0621',
      body:
          '${user.displayName} \u0627\u0634\u062a\u0631\u0649 ${request.itemName}',
      type: NotificationType.requestPurchased,
      createdBy: user.userId,
      roundId: request.roundId,
      requestId: request.requestId,
      itemName: request.itemName,
    );
  }

  Future<void> notifyRoundOpened({
    required AppUser user,
    required String roundId,
    required String roundName,
  }) {
    return createNotification(
      title: '\u062c\u0645\u0639\u064a\u0629 \u062c\u062f\u064a\u062f\u0629',
      body: '${user.displayName} \u0641\u062a\u062d $roundName',
      type: NotificationType.roundOpened,
      createdBy: user.userId,
      roundId: roundId,
    );
  }

  Future<void> notifyShoppingStarted({
    required AppUser user,
    required String roundId,
    required String roundName,
  }) {
    return createNotification(
      title: '\u0628\u062f\u0621 \u0627\u0644\u062c\u0645\u0639\u064a\u0629',
      body: '${user.displayName} \u0628\u062f\u0623 $roundName',
      type: NotificationType.shoppingStarted,
      createdBy: user.userId,
      roundId: roundId,
    );
  }

  Future<void> notifyRoundClosed({
    required String roundId,
    required String roundName,
    String createdBy = 'system',
  }) {
    return createNotification(
      title:
          '\u0625\u063a\u0644\u0627\u0642 \u0627\u0644\u0637\u0644\u0628\u0627\u062a',
      body: '\u062a\u0645 \u0625\u063a\u0644\u0627\u0642 $roundName',
      type: NotificationType.roundClosed,
      createdBy: createdBy,
      roundId: roundId,
    );
  }

  Future<void> sendAdminMessage({
    required AppUser admin,
    required String title,
    required String body,
  }) {
    return createNotification(
      title: title,
      body: body,
      type: NotificationType.adminMessage,
      createdBy: admin.userId,
    );
  }
}
