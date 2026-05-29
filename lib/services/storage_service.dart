import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final _storage = FirebaseStorage.instance;

  Future<String> uploadReviewImage(File file, String userId) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final ref = _storage.ref('reviews/$userId/$timestamp.jpg');
    final task = await ref.putFile(file, SettableMetadata(contentType: 'image/jpeg'));
    return await task.ref.getDownloadURL();
  }

  Future<String> uploadProfilePhoto(File file, String userId) async {
    final ref = _storage.ref('profiles/$userId/avatar.jpg');
    final task = await ref.putFile(file, SettableMetadata(contentType: 'image/jpeg'));
    return await task.ref.getDownloadURL();
  }
}