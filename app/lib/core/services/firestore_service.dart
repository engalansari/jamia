import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  FirestoreService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get users =>
      _firestore.collection('users');
  CollectionReference<Map<String, dynamic>> get categories =>
      _firestore.collection('categories');
  CollectionReference<Map<String, dynamic>> get units =>
      _firestore.collection('units');
  CollectionReference<Map<String, dynamic>> get items =>
      _firestore.collection('items');
  CollectionReference<Map<String, dynamic>> get rounds =>
      _firestore.collection('rounds');
  CollectionReference<Map<String, dynamic>> get requests =>
      _firestore.collection('requests');
  CollectionReference<Map<String, dynamic>> get logs =>
      _firestore.collection('logs');
  CollectionReference<Map<String, dynamic>> get notifications =>
      _firestore.collection('notifications');
}
