enum UserRole { admin, regular }

enum UserStatus { active, disabled }

enum RoundStatus { open, closed }

enum RequestPriority { normal, medium, important }

enum RequestStatus { needed, purchased, unavailable }

enum LogActionType {
  userCreated,
  userUpdated,
  userDisabled,
  categoryCreated,
  categoryUpdated,
  itemCreated,
  itemUpdated,
  roundOpened,
  roundClosed,
  requestCreated,
  requestUpdated,
  requestDeleted,
  requestPurchased,
  notificationSent,
}

enum NotificationType {
  requestCreated,
  requestUpdated,
  requestDeleted,
  requestPurchased,
  roundOpened,
  roundClosed,
  closingSoon,
  imageUpdated,
  adminMessage,
}

T enumFromName<T extends Enum>(List<T> values, String? name, T fallback) {
  for (final value in values) {
    if (value.name == name) return value;
  }
  return fallback;
}
