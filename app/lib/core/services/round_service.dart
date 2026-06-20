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
      final carriedRound = await _currentOpenRound();
      if (carriedRound != null && carriedRound.isOpen) return carriedRound;
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
    );

    await doc.set(round.toJson());
    await _notificationService.notifyRoundOpened(
      user: createdBy,
      roundId: round.roundId,
      roundName: round.name,
    );
    return round;
  }

  Future<void> closeRound(String roundId) async {
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
      await _carryOverNeededRequests(round);
    }
  }

  Future<void> closeRoundIfExpired(ShoppingRound round) async {
    if (round.status == RoundStatus.open && !round.isOpen) {
      await closeRound(round.roundId);
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
