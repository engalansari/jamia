import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/app_user.dart';
import '../models/model_enums.dart';
import '../models/shopping_request.dart';
import '../models/shopping_round.dart';
import 'notification_service.dart';

class RoundSummary {
  const RoundSummary({
    required this.round,
    required this.neededRequestCount,
    required this.neededItemCount,
  });

  final ShoppingRound? round;
  final int neededRequestCount;
  final int neededItemCount;
}

class RoundService {
  RoundService({
    FirebaseFirestore? firestore,
    NotificationService? notificationService,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _notificationService = notificationService ?? NotificationService();

  final FirebaseFirestore _firestore;
  final NotificationService _notificationService;

  CollectionReference<Map<String, dynamic>> get _rounds =>
      _firestore.collection('rounds');
  CollectionReference<Map<String, dynamic>> get _requests =>
      _firestore.collection('requests');

  static const _requestCollectionWindow = Duration(days: 365);

  Stream<ShoppingRound?> watchCurrentRound() {
    return _rounds
        .where('status', isEqualTo: RoundStatus.open.name)
        .limit(1)
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isEmpty) return null;
          final doc = snapshot.docs.first;
          return ShoppingRound.fromJson({...doc.data(), 'roundId': doc.id});
        });
  }

  Stream<List<ShoppingRequest>> watchNeededRequests(String roundId) {
    return _requests
        .where('roundId', isEqualTo: roundId)
        .where('status', isEqualTo: RequestStatus.needed.name)
        .snapshots()
        .map((snapshot) {
          final requests = snapshot.docs
              .map(
                (doc) => ShoppingRequest.fromJson({
                  ...doc.data(),
                  'requestId': doc.id,
                }),
              )
              .toList();
          requests.sort((a, b) => b.requestedAt.compareTo(a.requestedAt));
          return requests;
        });
  }

  Future<ShoppingRound> openRound({
    required AppUser createdBy,
    required Duration duration,
  }) async {
    final now = DateTime.now();
    await _closeOpenRounds(carryOverNeeded: false);
    return _createRound(
      createdBy: createdBy,
      createdAt: now,
      closeAt: now.add(duration),
      shoppingStartedAt: now,
    );
  }

  Future<ShoppingRound> createRequestRound({required AppUser createdBy}) async {
    final existingRound = await _currentOpenRound();
    if (existingRound != null && existingRound.isOpen) return existingRound;
    if (existingRound != null) {
      await closeRound(existingRound.roundId);
    }

    final now = DateTime.now();
    await _closeOpenRounds(carryOverNeeded: false);
    return _createRound(
      createdBy: createdBy,
      createdAt: now,
      closeAt: now.add(_requestCollectionWindow),
    );
  }

  Future<void> startShoppingRound({
    required AppUser startedBy,
    required Duration duration,
    ShoppingRound? round,
  }) async {
    final openRound = round?.isOpen == true
        ? round!
        : await createRequestRound(createdBy: startedBy);
    final now = DateTime.now();
    await _rounds.doc(openRound.roundId).set({
      'closeAt': now.add(duration).toIso8601String(),
      'shoppingStartedAt': now.toIso8601String(),
      'shoppingStartedBy': startedBy.userId,
      'shoppingStartedByName': startedBy.displayName,
    }, SetOptions(merge: true));
    await _activateNewListRequests(openRound.roundId);
    await _notificationService.notifyShoppingStarted(
      user: startedBy,
      roundId: openRound.roundId,
      roundName: openRound.name,
    );
  }

  Future<void> cancelShoppingTime(ShoppingRound round) async {
    await _rounds.doc(round.roundId).set({
      'closeAt': DateTime.now().add(_requestCollectionWindow).toIso8601String(),
      'shoppingStartedAt': FieldValue.delete(),
      'shoppingStartedBy': FieldValue.delete(),
      'shoppingStartedByName': FieldValue.delete(),
    }, SetOptions(merge: true));
  }

  Future<void> finishShoppingRound(ShoppingRound round) async {
    final now = DateTime.now();
    await _moveNeededRequestsToNewList(round.roundId);
    await _rounds.doc(round.roundId).set({
      'closeAt': now.add(_requestCollectionWindow).toIso8601String(),
      'shoppingStartedAt': FieldValue.delete(),
      'shoppingStartedBy': FieldValue.delete(),
      'shoppingStartedByName': FieldValue.delete(),
      'shoppingFinishedAt': now.toIso8601String(),
    }, SetOptions(merge: true));
  }

  Future<ShoppingRound> _createRound({
    required AppUser createdBy,
    required DateTime createdAt,
    required DateTime closeAt,
    DateTime? shoppingStartedAt,
  }) async {
    final doc = _rounds.doc();
    final round = ShoppingRound(
      roundId: doc.id,
      name: _roundName(createdAt),
      date: DateTime(createdAt.year, createdAt.month, createdAt.day),
      closeAt: closeAt,
      status: RoundStatus.open,
      createdBy: createdBy.userId,
      createdAt: createdAt,
      shoppingStartedAt: shoppingStartedAt,
      shoppingStartedBy: shoppingStartedAt == null ? null : createdBy.userId,
      shoppingStartedByName: shoppingStartedAt == null
          ? null
          : createdBy.displayName,
    );

    await doc.set(round.toJson());
    await _notificationService.notifyRoundOpened(
      user: createdBy,
      roundId: round.roundId,
      roundName: round.name,
    );
    return round;
  }

  Future<void> closeRound(
    String roundId, {
    bool carryOverNeededRequests = false,
  }) async {
    final snapshot = await _rounds.doc(roundId).get();
    final round = snapshot.data() == null
        ? null
        : ShoppingRound.fromJson({...snapshot.data()!, 'roundId': snapshot.id});
    await _rounds.doc(roundId).set({
      'status': RoundStatus.closed.name,
      'closedAt': DateTime.now().toIso8601String(),
    }, SetOptions(merge: true));
    if (round != null) {
      await _notificationService.notifyRoundClosed(
        roundId: round.roundId,
        roundName: round.name,
        createdBy: round.createdBy,
      );
      if (carryOverNeededRequests) {
        await _carryOverNeededRequests(round);
      }
    }
  }

  Future<void> closeRoundIfExpired(ShoppingRound round) async {
    return;
  }

  Future<void> cleanupClosedHistoryOlderThan30Days() async {
    final cutoff = DateTime.now().subtract(const Duration(days: 30));
    final snapshot = await _rounds
        .where('status', isEqualTo: RoundStatus.closed.name)
        .get();
    final staleRounds = <ShoppingRound>[];
    for (final doc in snapshot.docs) {
      final round = ShoppingRound.fromJson({...doc.data(), 'roundId': doc.id});
      final closedAt = _dateTimeFromValue(doc.data()['closedAt']);
      if (closedAt != null && closedAt.isBefore(cutoff)) {
        staleRounds.add(round);
      }
    }
    for (final round in staleRounds) {
      await _deleteRoundHistory(round.roundId);
    }
  }

  Future<void> _closeOpenRounds({required bool carryOverNeeded}) async {
    final snapshot = await _rounds
        .where('status', isEqualTo: RoundStatus.open.name)
        .get();
    final batch = _firestore.batch();
    final rounds = <ShoppingRound>[];
    for (final doc in snapshot.docs) {
      rounds.add(ShoppingRound.fromJson({...doc.data(), 'roundId': doc.id}));
      batch.set(doc.reference, {
        'status': RoundStatus.closed.name,
        'closedAt': DateTime.now().toIso8601String(),
      }, SetOptions(merge: true));
    }
    await batch.commit();
    for (final round in rounds) {
      await _notificationService.notifyRoundClosed(
        roundId: round.roundId,
        roundName: round.name,
        createdBy: round.createdBy,
      );
      if (carryOverNeeded) {
        await _carryOverNeededRequests(round);
      }
    }
  }

  Future<ShoppingRound?> _currentOpenRound() async {
    final snapshot = await _rounds
        .where('status', isEqualTo: RoundStatus.open.name)
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) return null;
    final doc = snapshot.docs.first;
    return ShoppingRound.fromJson({...doc.data(), 'roundId': doc.id});
  }

  Future<void> _carryOverNeededRequests(ShoppingRound closedRound) async {
    final snapshot = await _requests
        .where('roundId', isEqualTo: closedRound.roundId)
        .where('status', isEqualTo: RequestStatus.needed.name)
        .get();
    if (snapshot.docs.isEmpty) return;

    final now = DateTime.now();
    final nextRoundDoc = _rounds.doc();
    final nextRound = ShoppingRound(
      roundId: nextRoundDoc.id,
      name: _roundName(now),
      date: DateTime(now.year, now.month, now.day),
      closeAt: now.add(_requestCollectionWindow),
      status: RoundStatus.open,
      createdBy: closedRound.createdBy,
      createdAt: now,
    );

    final batch = _firestore.batch();
    batch.set(nextRoundDoc, nextRound.toJson());
    for (final doc in snapshot.docs) {
      batch.set(doc.reference, {
        'roundId': nextRound.roundId,
        'requestedAt': now.toIso8601String(),
        'carriedFromRoundId': closedRound.roundId,
      }, SetOptions(merge: true));
    }
    await batch.commit();
  }

  Future<void> _moveNeededRequestsToNewList(String roundId) async {
    final snapshot = await _requests
        .where('roundId', isEqualTo: roundId)
        .where('status', isEqualTo: RequestStatus.needed.name)
        .get();
    if (snapshot.docs.isEmpty) return;

    var batch = _firestore.batch();
    var operationCount = 0;
    final now = DateTime.now().toIso8601String();
    for (final doc in snapshot.docs) {
      batch.set(doc.reference, {
        'status': RequestStatus.newList.name,
        'movedToNewListAt': now,
      }, SetOptions(merge: true));
      operationCount++;
      if (operationCount == 450) {
        await batch.commit();
        batch = _firestore.batch();
        operationCount = 0;
      }
    }
    if (operationCount > 0) await batch.commit();
  }

  Future<void> _activateNewListRequests(String roundId) async {
    final snapshot = await _requests
        .where('roundId', isEqualTo: roundId)
        .where('status', isEqualTo: RequestStatus.newList.name)
        .get();
    if (snapshot.docs.isEmpty) return;

    var batch = _firestore.batch();
    var operationCount = 0;
    final now = DateTime.now().toIso8601String();
    for (final doc in snapshot.docs) {
      batch.set(doc.reference, {
        'status': RequestStatus.needed.name,
        'activatedFromNewListAt': now,
      }, SetOptions(merge: true));
      operationCount++;
      if (operationCount == 450) {
        await batch.commit();
        batch = _firestore.batch();
        operationCount = 0;
      }
    }
    if (operationCount > 0) await batch.commit();
  }

  Future<void> _deleteRoundHistory(String roundId) async {
    await _deleteQuery(_requests.where('roundId', isEqualTo: roundId));
    await _deleteQuery(
      _firestore
          .collection('notifications')
          .where('roundId', isEqualTo: roundId),
    );
    await _deleteQuery(
      _firestore.collection('inAppAlerts').where('roundId', isEqualTo: roundId),
    );
    await _rounds.doc(roundId).delete();
  }

  Future<void> _deleteQuery(Query<Map<String, dynamic>> query) async {
    final snapshot = await query.get();
    if (snapshot.docs.isEmpty) return;
    var batch = _firestore.batch();
    var operationCount = 0;
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
      operationCount++;
      if (operationCount == 450) {
        await batch.commit();
        batch = _firestore.batch();
        operationCount = 0;
      }
    }
    if (operationCount > 0) await batch.commit();
  }

  DateTime? _dateTimeFromValue(Object? value) {
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

  String _roundName(DateTime date) {
    const weekdays = [
      '\u0627\u0644\u0627\u062b\u0646\u064a\u0646',
      '\u0627\u0644\u062b\u0644\u0627\u062b\u0627\u0621',
      '\u0627\u0644\u0623\u0631\u0628\u0639\u0627\u0621',
      '\u0627\u0644\u062e\u0645\u064a\u0633',
      '\u0627\u0644\u062c\u0645\u0639\u0629',
      '\u0627\u0644\u0633\u0628\u062a',
      '\u0627\u0644\u0623\u062d\u062f',
    ];
    return '\u062c\u0645\u0639\u064a\u0629 ${weekdays[date.weekday - 1]}';
  }
}
