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

class ShoppingRequest {
  const ShoppingRequest({
    required this.requestId,
    required this.roundId,
    required this.itemId,
    required this.itemName,
    required this.quantity,
    required this.unit,
    required this.priority,
    required this.requestedBy,
    required this.requestedAt,
    required this.status,
    this.categoryId,
    this.categoryName,
    this.requestedByName,
    this.note,
    this.imageUrl,
    this.thumbnailUrl,
    this.purchasedBy,
    this.purchasedByName,
    this.purchasedAt,
  });

  final String requestId;
  final String roundId;
  final String itemId;
  final String itemName;
  final String? categoryId;
  final String? categoryName;
  final double quantity;
  final String unit;
  final RequestPriority priority;
  final String? note;
  final String? imageUrl;
  final String? thumbnailUrl;
  final String requestedBy;
  final String? requestedByName;
  final DateTime requestedAt;
  final RequestStatus status;
  final String? purchasedBy;
  final String? purchasedByName;
  final DateTime? purchasedAt;

  bool get isPurchased => status == RequestStatus.purchased;
  bool get isNeeded => status == RequestStatus.needed;

  factory ShoppingRequest.fromJson(Map<String, dynamic> json) {
    return ShoppingRequest(
      requestId: json['requestId'] as String? ?? '',
      roundId: json['roundId'] as String? ?? '',
      itemId: json['itemId'] as String? ?? '',
      itemName: json['itemName'] as String? ?? '',
      categoryId: json['categoryId'] as String?,
      categoryName: json['categoryName'] as String?,
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0,
      unit: json['unit'] as String? ?? '',
      priority: enumFromName(
        RequestPriority.values,
        json['priority'] as String?,
        RequestPriority.normal,
      ),
      note: json['note'] as String?,
      imageUrl: json['imageUrl'] as String?,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      requestedBy: json['requestedBy'] as String? ?? '',
      requestedByName: json['requestedByName'] as String?,
      requestedAt:
          _dateTimeFromJsonValue(json['requestedAt']) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      status: enumFromName(
        RequestStatus.values,
        json['status'] as String?,
        RequestStatus.needed,
      ),
      purchasedBy: json['purchasedBy'] as String?,
      purchasedByName: json['purchasedByName'] as String?,
      purchasedAt: _dateTimeFromJsonValue(json['purchasedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'requestId': requestId,
      'roundId': roundId,
      'itemId': itemId,
      'itemName': itemName,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'quantity': quantity,
      'unit': unit,
      'priority': priority.name,
      'note': note,
      'imageUrl': imageUrl,
      'thumbnailUrl': thumbnailUrl,
      'requestedBy': requestedBy,
      'requestedByName': requestedByName,
      'requestedAt': requestedAt.toIso8601String(),
      'status': status.name,
      'purchasedBy': purchasedBy,
      'purchasedByName': purchasedByName,
      'purchasedAt': purchasedAt?.toIso8601String(),
    };
  }
}
