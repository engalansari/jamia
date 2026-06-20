import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  StorageService({FirebaseStorage? storage})
    : _storage = storage ?? FirebaseStorage.instance;

  final FirebaseStorage _storage;

  Future<String> uploadRequestImage({
    required String requestId,
    required Uint8List bytes,
    required String contentType,
  }) async {
    final ref = _storage.ref('requests/$requestId/original');
    final task = await ref.putData(
      bytes,
      SettableMetadata(contentType: contentType),
    );
    return task.ref.getDownloadURL();
  }
}
