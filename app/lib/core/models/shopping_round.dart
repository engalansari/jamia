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

class ShoppingRound {
  const ShoppingRound({
    required this.roundId,
    required this.name,
    required this.date,
    required this.closeAt,
    required this.status,
    required this.createdBy,
    required this.createdAt,
    this.shoppingStartedAt,
    this.shoppingStartedBy,
    this.shoppingStartedByName,
  });

  final String roundId;
  final String name;
  final DateTime date;
  final DateTime closeAt;
  final RoundStatus status;
  final String createdBy;
  final DateTime createdAt;
  final DateTime? shoppingStartedAt;
  final String? shoppingStartedBy;
  final String? shoppingStartedByName;

  bool get isOpen => status == RoundStatus.open;
  bool get isShopping => shoppingStartedAt != null;
  bool get isShoppingWindowExpired =>
      isShopping && !DateTime.now().isBefore(closeAt);
  bool get acceptsCurrentShoppingRequests => !isShoppingWindowExpired;

  Duration remainingFrom(DateTime now) {
    final remaining = closeAt.difference(now);
    return remaining.isNegative ? Duration.zero : remaining;
  }

  factory ShoppingRound.fromJson(Map<String, dynamic> json) {
    return ShoppingRound(
      roundId: json['roundId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      date:
          _dateTimeFromJsonValue(json['date']) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      closeAt:
          _dateTimeFromJsonValue(json['closeAt']) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      status: enumFromName(
        RoundStatus.values,
        json['status'] as String?,
        RoundStatus.closed,
      ),
      createdBy: json['createdBy'] as String? ?? '',
      createdAt:
          _dateTimeFromJsonValue(json['createdAt']) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      shoppingStartedAt: _dateTimeFromJsonValue(json['shoppingStartedAt']),
      shoppingStartedBy: json['shoppingStartedBy'] as String?,
      shoppingStartedByName: json['shoppingStartedByName'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'roundId': roundId,
      'name': name,
      'date': date.toIso8601String(),
      'closeAt': closeAt.toIso8601String(),
      'status': status.name,
      'createdBy': createdBy,
      'createdAt': createdAt.toIso8601String(),
      'shoppingStartedAt': shoppingStartedAt?.toIso8601String(),
      'shoppingStartedBy': shoppingStartedBy,
      'shoppingStartedByName': shoppingStartedByName,
    };
  }
}
