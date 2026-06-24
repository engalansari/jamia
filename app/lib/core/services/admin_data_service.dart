import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../firebase/firebase_options.dart';
import '../models/app_user.dart';
import '../models/category.dart';
import '../models/grocery_item.dart';
import '../models/model_enums.dart';
import '../models/unit_option.dart';
import 'auth_service.dart';

class AdminDataService {
  AdminDataService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Stream<List<AppUser>> watchUsers() {
    return _firestore.collection('users').snapshots().map((snapshot) {
      final users = snapshot.docs
          .map((doc) => AppUser.fromJson({...doc.data(), 'userId': doc.id}))
          .toList();
      users.sort((a, b) => a.displayName.compareTo(b.displayName));
      return users;
    });
  }

  Future<void> updateUser(AppUser user) {
    return _firestore
        .collection('users')
        .doc(user.userId)
        .set(user.toJson(), SetOptions(merge: true));
  }

  Future<AppUser> createUserAccount({
    required String displayName,
    required String username,
    required String password,
    required UserRole role,
    required UserStatus status,
  }) async {
    final normalizedUsername = username.trim().toLowerCase();
    final app = await Firebase.initializeApp(
      name: 'user-creator-${DateTime.now().microsecondsSinceEpoch}',
      options:
          DefaultFirebaseOptions.currentPlatformOrNull ??
          Firebase.app().options,
    );

    try {
      final auth = FirebaseAuth.instanceFor(app: app);
      final credential = await auth.createUserWithEmailAndPassword(
        email: AuthService.emailForUsername(normalizedUsername),
        password: password,
      );
      final firebaseUser = credential.user;
      if (firebaseUser == null) {
        throw FirebaseAuthException(
          code: 'missing-user',
          message: 'The user account was not returned after creation.',
        );
      }

      if (displayName.trim().isNotEmpty) {
        await firebaseUser.updateDisplayName(displayName.trim());
      }

      final user = AppUser(
        userId: firebaseUser.uid,
        displayName: displayName.trim(),
        username: normalizedUsername,
        role: role,
        status: status,
        createdAt: DateTime.now(),
      );
      await _firestore.collection('users').doc(user.userId).set(user.toJson());
      await auth.signOut();
      return user;
    } finally {
      await app.delete();
    }
  }

  Future<void> setUserStatus(AppUser user, UserStatus status) {
    return _firestore.collection('users').doc(user.userId).set({
      'status': status.name,
    }, SetOptions(merge: true));
  }

  Future<void> setUserRole(AppUser user, UserRole role) {
    return _firestore.collection('users').doc(user.userId).set({
      'role': role.name,
    }, SetOptions(merge: true));
  }

  Future<void> deleteUser(AppUser user) {
    return _firestore.collection('users').doc(user.userId).delete();
  }

  Stream<List<Category>> watchCategories() {
    return _firestore.collection('categories').snapshots().map((snapshot) {
      final categories = snapshot.docs
          .map(
            (doc) => Category.fromJson({...doc.data(), 'categoryId': doc.id}),
          )
          .toList();
      categories.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      return categories;
    });
  }

  Future<void> saveCategory(Category category) {
    final doc = category.categoryId.isEmpty
        ? _firestore.collection('categories').doc()
        : _firestore.collection('categories').doc(category.categoryId);
    return doc.set({
      ...category.toJson(),
      'categoryId': doc.id,
    }, SetOptions(merge: true));
  }

  Stream<List<UnitOption>> watchUnits() {
    return _firestore.collection('units').snapshots().map((snapshot) {
      final units = snapshot.docs
          .map((doc) => UnitOption.fromJson({...doc.data(), 'unitId': doc.id}))
          .toList();
      units.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      return units;
    });
  }

  Future<void> saveUnit(UnitOption unit) {
    final doc = unit.unitId.isEmpty
        ? _firestore.collection('units').doc()
        : _firestore.collection('units').doc(unit.unitId);
    return doc.set({
      ...unit.toJson(),
      'unitId': doc.id,
    }, SetOptions(merge: true));
  }

  Stream<List<GroceryItem>> watchItems() {
    return _firestore.collection('items').snapshots().map((snapshot) {
      final items = snapshot.docs
          .map((doc) => GroceryItem.fromJson({...doc.data(), 'itemId': doc.id}))
          .toList();
      items.sort((a, b) => a.nameAr.compareTo(b.nameAr));
      return items;
    });
  }

  Future<void> saveItem(GroceryItem item) {
    final doc = item.itemId.isEmpty
        ? _firestore.collection('items').doc()
        : _firestore.collection('items').doc(item.itemId);
    return doc.set({
      ...item.toJson(),
      'itemId': doc.id,
    }, SetOptions(merge: true));
  }

  Future<void> setItemFavorite(GroceryItem item, bool isFavorite) {
    return _firestore.collection('items').doc(item.itemId).set({
      'isFavorite': isFavorite,
    }, SetOptions(merge: true));
  }
}
