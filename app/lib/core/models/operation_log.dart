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

class OperationLog {
  const OperationLog({
    required this.logId,
    required this.actionType,
    required this.userId,
    required this.userName,
    required this.itemName,
    required this.details,
    required this.createdAt,
    this.roundId,
    this.requestId,
    this.categoryId,
    this.categoryName,
    this.quantity,
    this.unit,
  });

  final String logId;
  final LogActionType actionType;
  final String userId;
  final String userName;
  final String? roundId;
  final String? requestId;
  final String? categoryId;
  final String? categoryName;
  final String itemName;
  final String details;
  final double? quantity;
  final String? unit;
  final DateTime createdAt;

  factory OperationLog.fromJson(Map<String, dynamic> json) {
    return OperationLog(
      logId: json['logId'] as String? ?? '',
      actionType: enumFromName(
        LogActionType.values,
        json['actionType'] as String?,
        LogActionType.requestCreated,
      ),
      userId: json['userId'] as String? ?? '',
      userName: json['userName'] as String? ?? '',
      roundId: json['roundId'] as String?,
      requestId: json['requestId'] as String?,
      categoryId: json['categoryId'] as String?,
      categoryName: json['categoryName'] as String?,
      itemName: json['itemName'] as String? ?? '',
      details: json['details'] as String? ?? '',
      quantity: (json['quantity'] as num?)?.toDouble(),
      unit: json['unit'] as String?,
      createdAt:
          _dateTimeFromJsonValue(json['createdAt']) ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'logId': logId,
      'actionType': actionType.name,
      'userId': userId,
      'userName': userName,
      'roundId': roundId,
      'requestId': requestId,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'itemName': itemName,
      'details': details,
      'quantity': quantity,
      'unit': unit,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
