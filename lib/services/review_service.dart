import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/game_review.dart';

class ReviewService {
  final _col = FirebaseFirestore.instance.collection('reviews');

  // Stream semua review, urut terbaru (diurutkan in-memory untuk menghindari composite index error)
  Stream<List<GameReview>> streamReviews({String? genre}) {
    Query q = _col;
    if (genre != null && genre != 'Semua') {
      q = q.where('genre', isEqualTo: genre);
    }
    return q.snapshots().map(
      (snap) {
        final list = snap.docs.map((d) => GameReview.fromFirestore(d)).toList();
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return list;
      },
    );
  }

  // Stream review milik user tertentu (diurutkan in-memory untuk menghindari composite index error)
  Stream<List<GameReview>> streamUserReviews(String userId) {
    return _col
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snap) {
          final list = snap.docs.map((d) => GameReview.fromFirestore(d)).toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
  }

  // Tambah review baru
  Future<String> addReview(GameReview review) async {
    final ref = await _col.add(review.toFirestore());
    return ref.id;
  }

  // Hapus review
  Future<void> deleteReview(String reviewId) async {
    await _col.doc(reviewId).delete();
  }

  // Toggle like
  Future<void> toggleLike(String reviewId, bool isLiked) async {
    await _col.doc(reviewId).update({
      'likesCount': FieldValue.increment(isLiked ? 1 : -1),
    });
  }
}