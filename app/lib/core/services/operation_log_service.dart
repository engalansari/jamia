import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/app_user.dart';
import '../models/model_enums.dart';
import '../models/operation_log.dart';
import '../models/shopping_request.dart';

class OperationLogService {
  OperationLogService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _logs =>
      _firestore.collection('operationLogs');

  Stream<List<OperationLog>> watchLogs({int limit = 100}) {
    return _logs.limit(limit).snapshots().map((snapshot) {
      final logs = snapshot.docs
          .map((doc) => OperationLog.fromJson({...doc.data(), 'logId': doc.id}))
          .toList();
      logs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return logs;
    });
  }

  Future<void> recordRequestAction({
    required LogActionType actionType,
    required AppUser user,
    required ShoppingRequest request,
    required String details,
  }) {
    final doc = _logs.doc();
    final log = OperationLog(
      logId: doc.id,
      actionType: actionType,
      userId: user.userId,
      userName: user.displayName,
      roundId: request.roundId,
      requestId: request.requestId,
      categoryId: request.categoryId,
      categoryName: request.categoryName,
      itemName: request.itemName,
      details: details,
      quantity: request.quantity,
      unit: request.unit,
      createdAt: DateTime.now(),
    );
    return doc.set(log.toJson());
  }
}
