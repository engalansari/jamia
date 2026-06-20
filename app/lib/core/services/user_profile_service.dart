import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/app_user.dart';

class UserProfileService {
  UserProfileService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _userDoc(String userId) {
    return _firestore.collection('users').doc(userId);
  }

  Future<AppUser?> getUser(String userId) async {
    final snapshot = await _userDoc(userId).get();
    final data = snapshot.data();
    if (!snapshot.exists || data == null) return null;
    return AppUser.fromJson({...data, 'userId': data['userId'] ?? snapshot.id});
  }

  Stream<AppUser?> watchUser(String userId) {
    return _userDoc(userId).snapshots().map((snapshot) {
      final data = snapshot.data();
      if (!snapshot.exists || data == null) return null;
      return AppUser.fromJson({
        ...data,
        'userId': data['userId'] ?? snapshot.id,
      });
    });
  }

  Future<void> updateLastLogin(String userId) {
    return _userDoc(userId).set({
      'userId': userId,
      'lastLogin': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
