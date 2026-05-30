import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final _storage = FirebaseStorage.instance;

  Future<String> uploadReviewImage({required Uint8List bytes, required String userId}) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final ref = _storage.ref('reviews/$userId/$timestamp.jpg');
    try {
      print('STORAGE: starting upload to ${ref.fullPath} (${bytes.lengthInBytes} bytes)');
      final taskFuture = ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
      final taskSnapshot = await taskFuture.timeout(const Duration(seconds: 30));
      final url = await taskSnapshot.ref.getDownloadURL();
      print('STORAGE: upload finished, url=$url');
      return url;
    } catch (e) {
      print('STORAGE: upload error: $e');
      rethrow;
    }
  }

  Future<String> uploadProfilePhoto({required Uint8List bytes, required String userId}) async {
    final ref = _storage.ref('profiles/$userId/avatar.jpg');
    try {
      print('STORAGE: starting avatar upload to ${ref.fullPath} (${bytes.lengthInBytes} bytes)');
      final taskFuture = ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
      final taskSnapshot = await taskFuture.timeout(const Duration(seconds: 30));
      final url = await taskSnapshot.ref.getDownloadURL();
      print('STORAGE: avatar upload finished, url=$url');
      return url;
    } catch (e) {
      print('STORAGE: avatar upload error: $e');
      rethrow;
    }
  }
}