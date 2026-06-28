import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/app_user.dart';
import '../models/grocery_item.dart';
import '../models/shopping_round.dart';

class InAppAlert {
  const InAppAlert({
    required this.alertId,
    required this.targetUserId,
    required this.message,
    required this.createdAt,
  });

  final String alertId;
  final String targetUserId;
  final String message;
  final DateTime createdAt;

  factory InAppAlert.fromJson(Map<String, dynamic> json) {
    return InAppAlert(
      alertId: json['alertId'] as String? ?? '',
      targetUserId: json['targetUserId'] as String? ?? '',
      message: json['message'] as String? ?? '',
      createdAt:
          _dateTimeFromJsonValue(json['createdAt']) ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

class InAppAlertService {
  InAppAlertService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _alerts =>
      _firestore.collection('inAppAlerts');

  Stream<List<InAppAlert>> watchPendingAlerts(String userId) {
    return _alerts
        .where('targetUserId', isEqualTo: userId)
        .where('seen', isEqualTo: false)
        .snapshots()
        .map((snapshot) {
          final alerts = snapshot.docs
              .map(
                (doc) =>
                    InAppAlert.fromJson({...doc.data(), 'alertId': doc.id}),
              )
              .toList();
          alerts.sort((a, b) => a.createdAt.compareTo(b.createdAt));
          return alerts;
        });
  }

  Future<void> markSeen(String alertId) {
    return _alerts.doc(alertId).set({
      'seen': true,
      'seenAt': DateTime.now().toIso8601String(),
    }, SetOptions(merge: true));
  }

  Future<void> notifyLateRequestAdded({
    required ShoppingRound round,
    required AppUser addedBy,
    required GroceryItem item,
  }) async {
    final targetUserId = round.shoppingStartedBy ?? round.createdBy;
    if (targetUserId.isEmpty || targetUserId == addedBy.userId) return;

    final doc = _alerts.doc();
    await doc.set({
      'alertId': doc.id,
      'targetUserId': targetUserId,
      'createdBy': addedBy.userId,
      'roundId': round.roundId,
      'itemName': item.nameAr,
      'message':
          '${addedBy.displayName} \u0623\u0636\u0627\u0641 ${item.nameAr} \u0648\u062a\u0645 \u0648\u0636\u0639\u0647\u0627 \u0628\u0627\u0644\u0642\u0627\u0626\u0645\u0629 \u0627\u0644\u062c\u062f\u064a\u062f\u0629.',
      'createdAt': DateTime.now().toIso8601String(),
      'seen': false,
    });
  }
}

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
