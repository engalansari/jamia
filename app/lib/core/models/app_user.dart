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

class AppUser {
  const AppUser({
    required this.userId,
    required this.displayName,
    required this.username,
    required this.role,
    required this.status,
    required this.createdAt,
    this.lastLogin,
  });

  final String userId;
  final String displayName;
  final String username;
  final UserRole role;
  final UserStatus status;
  final DateTime createdAt;
  final DateTime? lastLogin;

  bool get isAdmin => role == UserRole.admin;
  bool get isActive => status == UserStatus.active;
  String get roleLabel => isAdmin
      ? '\u0645\u062f\u064a\u0631'
      : '\u0645\u0633\u062a\u062e\u062f\u0645';

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      userId: json['userId'] as String? ?? '',
      displayName: json['displayName'] as String? ?? '',
      username: json['username'] as String? ?? '',
      role: enumFromName(
        UserRole.values,
        json['role'] as String?,
        UserRole.regular,
      ),
      status: enumFromName(
        UserStatus.values,
        json['status'] as String?,
        UserStatus.active,
      ),
      createdAt:
          _dateTimeFromJsonValue(json['createdAt']) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      lastLogin: _dateTimeFromJsonValue(json['lastLogin']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'displayName': displayName,
      'username': username,
      'role': role.name,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'lastLogin': lastLogin?.toIso8601String(),
    };
  }

  AppUser copyWith({
    String? userId,
    String? displayName,
    String? username,
    UserRole? role,
    UserStatus? status,
    DateTime? createdAt,
    DateTime? lastLogin,
  }) {
    return AppUser(
      userId: userId ?? this.userId,
      displayName: displayName ?? this.displayName,
      username: username ?? this.username,
      role: role ?? this.role,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
    );
  }
}
