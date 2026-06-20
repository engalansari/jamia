import 'package:flutter/material.dart';

import '../../core/models/app_notification.dart';
import '../../core/models/app_user.dart';
import '../../core/models/model_enums.dart';
import '../../core/services/notification_service.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key, required this.currentUser});

  final AppUser currentUser;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '\u0627\u0644\u0625\u0634\u0639\u0627\u0631\u0627\u062a',
        ),
      ),
      body: StreamBuilder<List<AppNotification>>(
        stream: NotificationService().watchNotificationsForUser(
          currentUser.userId,
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final notifications = snapshot.data ?? const <AppNotification>[];
          if (notifications.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  '\u0644\u0627 \u062a\u0648\u062c\u062f \u0625\u0634\u0639\u0627\u0631\u0627\u062a \u062d\u0627\u0644\u064a\u0627.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: notifications.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(_notificationIcon(notification.type)),
                title: Text(notification.title),
                subtitle: Text(notification.body),
                trailing: Text(_formatTime(notification.createdAt)),
              );
            },
          );
        },
      ),
    );
  }
}

IconData _notificationIcon(NotificationType type) {
  switch (type) {
    case NotificationType.requestCreated:
      return Icons.add_shopping_cart;
    case NotificationType.requestUpdated:
      return Icons.edit_notifications;
    case NotificationType.requestDeleted:
      return Icons.delete_outline;
    case NotificationType.requestPurchased:
      return Icons.check_circle_outline;
    case NotificationType.roundOpened:
      return Icons.storefront;
    case NotificationType.roundClosed:
    case NotificationType.closingSoon:
      return Icons.timer_off;
    case NotificationType.imageUpdated:
      return Icons.image;
    case NotificationType.adminMessage:
      return Icons.campaign;
  }
}

String _formatTime(DateTime dateTime) {
  final hour = dateTime.hour.toString().padLeft(2, '0');
  final minute = dateTime.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}
