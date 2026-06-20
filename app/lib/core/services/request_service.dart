import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/app_user.dart';
import '../models/grocery_item.dart';
import '../models/model_enums.dart';
import '../models/shopping_request.dart';
import 'default_catalog.dart';
import 'notification_service.dart';
import 'operation_log_service.dart';
import 'storage_service.dart';

class RequestService {
  RequestService({
    FirebaseFirestore? firestore,
    StorageService? storageService,
    OperationLogService? logService,
    NotificationService? notificationService,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _storageService = storageService ?? StorageService(),
       _logService = logService ?? OperationLogService(),
       _notificationService = notificationService ?? NotificationService();

  final FirebaseFirestore _firestore;
  final StorageService _storageService;
  final OperationLogService _logService;
  final NotificationService _notificationService;

  CollectionReference<Map<String, dynamic>> get _categories =>
      _firestore.collection('categories');
  CollectionReference<Map<String, dynamic>> get _items =>
      _firestore.collection('items');
  CollectionReference<Map<String, dynamic>> get _requests =>
      _firestore.collection('requests');
  CollectionReference<Map<String, dynamic>> get _units =>
      _firestore.collection('units');

  Stream<List<ShoppingRequest>> watchRoundRequests({
    required String roundId,
    RequestStatus? status,
  }) {
    Query<Map<String, dynamic>> query = _requests.where(
      'roundId',
      isEqualTo: roundId,
    );
    if (status != null) {
      query = query.where('status', isEqualTo: status.name);
    }
    return query.snapshots().map((snapshot) {
      final requests = snapshot.docs
          .map(
            (doc) =>
                ShoppingRequest.fromJson({...doc.data(), 'requestId': doc.id}),
          )
          .toList();
      requests.sort((a, b) {
        final aDate = a.purchasedAt ?? a.requestedAt;
        final bDate = b.purchasedAt ?? b.requestedAt;
        return bDate.compareTo(aDate);
      });
      return requests;
    });
  }

  Stream<List<GroceryItem>> watchActiveItems({bool favoritesOnly = false}) {
    return _items.where('isActive', isEqualTo: true).snapshots().map((
      snapshot,
    ) {
      final items = snapshot.docs
          .map((doc) => GroceryItem.fromJson({...doc.data(), 'itemId': doc.id}))
          .where((item) => !favoritesOnly || item.isFavorite)
          .toList();
      items.sort((a, b) => a.nameAr.compareTo(b.nameAr));
      return items;
    });
  }

  Future<void> addRequest({
    required String roundId,
    required GroceryItem item,
    required double quantity,
    required String unit,
    required RequestPriority priority,
    required AppUser requestedBy,
    String? note,
    Uint8List? imageBytes,
    String? imageContentType,
  }) async {
    final existingSnapshot = await _requests
        .where('roundId', isEqualTo: roundId)
        .where('itemId', isEqualTo: item.itemId)
        .where('status', isEqualTo: RequestStatus.needed.name)
        .limit(1)
        .get();
    final doc = existingSnapshot.docs.isEmpty
        ? _requests.doc()
        : existingSnapshot.docs.first.reference;
    final now = DateTime.now();
    final uploadedImageUrl = imageBytes == null
        ? null
        : await _storageService.uploadRequestImage(
            requestId: doc.id,
            bytes: imageBytes,
            contentType: imageContentType ?? 'image/jpeg',
          );
    final categoryName = await _categoryName(item.categoryId);
    final imageUrl = uploadedImageUrl ?? item.defaultImageUrl;
    if (existingSnapshot.docs.isNotEmpty) {
      final existing = ShoppingRequest.fromJson({
        ...existingSnapshot.docs.first.data(),
        'requestId': existingSnapshot.docs.first.id,
      });
      final updatedQuantity = existing.quantity + quantity;
      final data = <String, dynamic>{
        'quantity': updatedQuantity,
        'unit': unit.trim().isEmpty ? existing.unit : unit,
        'priority': _highestPriority(existing.priority, priority).name,
        'updatedAt': now.toIso8601String(),
      };
      final trimmedNote = note?.trim();
      if (trimmedNote?.isNotEmpty == true) data['note'] = trimmedNote;
      if (imageUrl?.isNotEmpty == true) {
        data['imageUrl'] = imageUrl;
        data['thumbnailUrl'] = imageUrl;
      }
      await doc.set(data, SetOptions(merge: true));
      final updatedRequest = ShoppingRequest(
        requestId: existing.requestId,
        roundId: existing.roundId,
        itemId: existing.itemId,
        itemName: existing.itemName,
        categoryId: existing.categoryId,
        categoryName: existing.categoryName,
        quantity: updatedQuantity,
        unit: data['unit'] as String,
        priority: _highestPriority(existing.priority, priority),
        note: data['note'] as String? ?? existing.note,
        imageUrl: data['imageUrl'] as String? ?? existing.imageUrl,
        thumbnailUrl: data['thumbnailUrl'] as String? ?? existing.thumbnailUrl,
        requestedBy: existing.requestedBy,
        requestedByName: existing.requestedByName,
        requestedAt: existing.requestedAt,
        status: existing.status,
        purchasedBy: existing.purchasedBy,
        purchasedByName: existing.purchasedByName,
        purchasedAt: existing.purchasedAt,
      );
      await _logService.recordRequestAction(
        actionType: LogActionType.requestUpdated,
        user: requestedBy,
        request: updatedRequest,
        details: 'تم جمع كمية الصنف مع الطلب الموجود',
      );
      await _notificationService.notifyRequestUpdated(
        user: requestedBy,
        request: updatedRequest,
      );
      return;
    }

    final request = ShoppingRequest(
      requestId: doc.id,
      roundId: roundId,
      itemId: item.itemId,
      itemName: item.nameAr,
      categoryId: item.categoryId,
      categoryName: categoryName,
      quantity: quantity,
      unit: unit,
      priority: priority,
      note: note?.trim().isEmpty == true ? null : note?.trim(),
      requestedBy: requestedBy.userId,
      requestedByName: requestedBy.displayName,
      requestedAt: now,
      status: RequestStatus.needed,
      imageUrl: imageUrl,
      thumbnailUrl: imageUrl,
    );
    await doc.set(request.toJson());
    await _logService.recordRequestAction(
      actionType: LogActionType.requestCreated,
      user: requestedBy,
      request: request,
      details:
          '\u062a\u0645\u062a \u0625\u0636\u0627\u0641\u0629 \u0637\u0644\u0628 \u062c\u062f\u064a\u062f',
    );
    await _notificationService.notifyRequestCreated(
      user: requestedBy,
      request: request,
    );
  }

  Future<void> updateRequest({
    required ShoppingRequest request,
    required AppUser updatedBy,
    required double quantity,
    required String unit,
    required RequestPriority priority,
    String? note,
    Uint8List? imageBytes,
    String? imageContentType,
  }) async {
    final uploadedImageUrl = imageBytes == null
        ? null
        : await _storageService.uploadRequestImage(
            requestId: request.requestId,
            bytes: imageBytes,
            contentType: imageContentType ?? 'image/jpeg',
          );
    final data = <String, dynamic>{
      'quantity': quantity,
      'unit': unit,
      'priority': priority.name,
      'note': note?.trim().isEmpty == true ? null : note?.trim(),
      'updatedAt': DateTime.now().toIso8601String(),
    };
    if (uploadedImageUrl != null) {
      data['imageUrl'] = uploadedImageUrl;
      data['thumbnailUrl'] = uploadedImageUrl;
    }
    await _requests.doc(request.requestId).set(data, SetOptions(merge: true));
    final updatedRequest = ShoppingRequest(
      requestId: request.requestId,
      roundId: request.roundId,
      itemId: request.itemId,
      itemName: request.itemName,
      categoryId: request.categoryId,
      categoryName: request.categoryName,
      quantity: quantity,
      unit: unit,
      priority: priority,
      requestedBy: request.requestedBy,
      requestedByName: request.requestedByName,
      requestedAt: request.requestedAt,
      status: request.status,
      note: note,
      imageUrl: uploadedImageUrl ?? request.imageUrl,
      thumbnailUrl: uploadedImageUrl ?? request.thumbnailUrl,
      purchasedBy: request.purchasedBy,
      purchasedByName: request.purchasedByName,
      purchasedAt: request.purchasedAt,
    );
    await _logService.recordRequestAction(
      actionType: LogActionType.requestUpdated,
      user: updatedBy,
      request: updatedRequest,
      details:
          '\u062a\u0645 \u062a\u0639\u062f\u064a\u0644 \u0627\u0644\u0637\u0644\u0628',
    );
    await _notificationService.notifyRequestUpdated(
      user: updatedBy,
      request: updatedRequest,
    );
  }

  Future<void> markPurchased({
    required ShoppingRequest request,
    required AppUser purchasedBy,
  }) async {
    final purchasedAt = DateTime.now();
    await _requests.doc(request.requestId).set({
      'status': RequestStatus.purchased.name,
      'purchasedBy': purchasedBy.userId,
      'purchasedByName': purchasedBy.displayName,
      'purchasedAt': purchasedAt.toIso8601String(),
    }, SetOptions(merge: true));
    final purchasedRequest = ShoppingRequest(
      requestId: request.requestId,
      roundId: request.roundId,
      itemId: request.itemId,
      itemName: request.itemName,
      categoryId: request.categoryId,
      categoryName: request.categoryName,
      quantity: request.quantity,
      unit: request.unit,
      priority: request.priority,
      requestedBy: request.requestedBy,
      requestedByName: request.requestedByName,
      requestedAt: request.requestedAt,
      status: RequestStatus.purchased,
      note: request.note,
      imageUrl: request.imageUrl,
      thumbnailUrl: request.thumbnailUrl,
      purchasedBy: purchasedBy.userId,
      purchasedByName: purchasedBy.displayName,
      purchasedAt: purchasedAt,
    );
    await _logService.recordRequestAction(
      actionType: LogActionType.requestPurchased,
      user: purchasedBy,
      request: purchasedRequest,
      details:
          '\u062a\u0645 \u0634\u0631\u0627\u0621 \u0627\u0644\u0637\u0644\u0628',
    );
    await _notificationService.notifyRequestPurchased(
      user: purchasedBy,
      request: purchasedRequest,
    );
  }

  Future<void> deleteRequest({
    required ShoppingRequest request,
    required AppUser deletedBy,
  }) async {
    await _requests.doc(request.requestId).delete();
    await _logService.recordRequestAction(
      actionType: LogActionType.requestDeleted,
      user: deletedBy,
      request: request,
      details: '\u062a\u0645 \u062d\u0630\u0641 \u0627\u0644\u0637\u0644\u0628',
    );
    await _notificationService.notifyRequestDeleted(
      user: deletedBy,
      request: request,
    );
  }

  Future<void> seedDefaultCatalog() async {
    await _deleteCatalogCollection(_items);
    await _deleteCatalogCollection(_categories);
    await _deleteCatalogCollection(_units);

    var batch = _firestore.batch();
    var operationCount = 0;

    Future<void> commitWhenFull() async {
      if (operationCount < 450) return;
      await batch.commit();
      batch = _firestore.batch();
      operationCount = 0;
    }

    for (final category in defaultCatalogCategories) {
      batch.set(_categories.doc(category.id), {
        'categoryId': category.id,
        'nameAr': category.nameAr,
        'nameEn': category.nameAr,
        'sortOrder': category.sortOrder,
        'isActive': true,
      });
      operationCount++;
      await commitWhenFull();
    }

    for (final unit in defaultCatalogUnits) {
      batch.set(_units.doc(unit.id), {
        'unitId': unit.id,
        'nameAr': unit.nameAr,
        'nameEn': unit.nameAr,
        'sortOrder': unit.sortOrder,
        'isActive': true,
      });
      operationCount++;
      await commitWhenFull();
    }

    for (final item in defaultCatalogItems) {
      batch.set(_items.doc(item.id), {
        'itemId': item.id,
        'nameAr': item.nameAr,
        'nameEn': item.nameAr,
        'categoryId': item.categoryId,
        'defaultUnit': item.defaultUnit,
        'isFavorite': false,
        'isActive': true,
        'defaultImageUrl': null,
      });
      operationCount++;
      await commitWhenFull();
    }

    if (operationCount > 0) {
      await batch.commit();
    }
  }

  Future<void> _deleteCatalogCollection(
    CollectionReference<Map<String, dynamic>> collection,
  ) async {
    final snapshot = await collection.get();
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

    if (operationCount > 0) {
      await batch.commit();
    }
  }

  Future<String?> _categoryName(String categoryId) async {
    if (categoryId.isEmpty) return null;
    final doc = await _categories.doc(categoryId).get();
    final data = doc.data();
    return data?['nameAr'] as String?;
  }

  RequestPriority _highestPriority(
    RequestPriority first,
    RequestPriority second,
  ) {
    int rank(RequestPriority priority) {
      switch (priority) {
        case RequestPriority.normal:
          return 0;
        case RequestPriority.medium:
          return 1;
        case RequestPriority.important:
          return 2;
      }
    }

    return rank(first) >= rank(second) ? first : second;
  }
}
