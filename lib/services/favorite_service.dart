import 'package:cloud_firestore/cloud_firestore.dart';

class FavoriteService {
  final _db = FirebaseFirestore.instance;

  CollectionReference _userFavCol(String userId) =>
      _db.collection('users').doc(userId).collection('favorites');

  // Cek apakah sebuah review sudah difavoritkan
  Stream<bool> isFavorite(String userId, String reviewId) {
    return _userFavCol(userId).doc(reviewId).snapshots().map((d) => d.exists);
  }

  // Stream daftar ID review yang difavoritkan user
  Stream<List<String>> streamFavoriteIds(String userId) {
    return _userFavCol(userId)
        .orderBy('savedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.id).toList());
  }

  // Toggle favorit
  Future<void> toggleFavorite(String userId, String reviewId, bool isFav) async {
    final ref = _userFavCol(userId).doc(reviewId);
    if (isFav) {
      await ref.delete();
    } else {
      await ref.set({'savedAt': FieldValue.serverTimestamp()});
    }
  }

  // Ambil data review dari daftar ID favorit
  Future<List<DocumentSnapshot>> fetchFavoriteReviews(List<String> ids) async {
    if (ids.isEmpty) return [];
    final futures = ids.map(
      (id) => _db.collection('reviews').doc(id).get(),
    );
    return Future.wait(futures);
  }
}
