import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/comment.dart';


class CommentService {
  final _db = FirebaseFirestore.instance;

  // Ambil semua komentar untuk sebuah review
  Stream<List<Comment>> streamComments(String reviewId) {
    return _db
        .collection('reviews')
        .doc(reviewId)
        .collection('comments')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snap) => snap.docs.map((d) => Comment.fromFirestore(d)).toList());
  }

  // Tambah komentar (atau balasan)
  Future<void> addComment(Comment comment) async {
    final ref = _db
        .collection('reviews')
        .doc(comment.reviewId)
        .collection('comments');
    await ref.add(comment.toFirestore());

    // Update jumlah komentar di review parent
    await _db.collection('reviews').doc(comment.reviewId).update({
      'commentsCount': FieldValue.increment(1),
    });
  }

  // Hapus komentar (hanya pemilik komentar)
  Future<void> deleteComment({
    required String reviewId,
    required String commentId,
  }) async {
    await _db
        .collection('reviews')
        .doc(reviewId)
        .collection('comments')
        .doc(commentId)
        .delete();

    await _db.collection('reviews').doc(reviewId).update({
      'commentsCount': FieldValue.increment(-1),
    });
  }
}