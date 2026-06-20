import 'model_enums.dart';

DateTime? _dateTimeFromJsonValue(Object? value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  final dynamic dynamicValue = value;
  try {
    final Object? maybeDate = dynamicValue.toDate();
    if (maybeDate is DateTime) return maybeDate;
  } catch (_) {
    // Firestore Timestamp is handled above when available.
  }
  return null;
}

class AppNotification {
  const AppNotification({
    required this.notificationId,
    required this.title,
    required this.body,
    required this.type,
    required this.createdBy,
    required this.createdAt,
    required this.targetUsers,
    this.roundId,
    this.requestId,
    this.itemName,
  });

  final String notificationId;
  final String title;
  final String body;
  final NotificationType type;
  final String createdBy;
  final DateTime createdAt;
  final List<String> targetUsers;
  final String? roundId;
  final String? requestId;
  final String? itemName;

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      notificationId: json['notificationId'] as String? ?? '',
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      type: enumFromName(
        NotificationType.values,
        json['type'] as String?,
        NotificationType.adminMessage,
      ),
      createdBy: json['createdBy'] as String? ?? '',
      createdAt:
          _dateTimeFromJsonValue(json['createdAt']) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      targetUsers: List<String>.from(json['targetUsers'] as List? ?? const []),
      roundId: json['roundId'] as String?,
      requestId: json['requestId'] as String?,
      itemName: json['itemName'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'notificationId': notificationId,
      'title': title,
      'body': body,
      'type': type.name,
      'createdBy': createdBy,
      'createdAt': createdAt.toIso8601String(),
      'targetUsers': targetUsers,
      'roundId': roundId,
      'requestId': requestId,
      'itemName': itemName,
    };
  }
}
