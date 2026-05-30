import 'package:cloud_firestore/cloud_firestore.dart';

class Comment {
  final String id;
  final String reviewId;
  final String? parentId;
  final String userId;
  final String userName;
  final String userPhotoUrl;
  final String text;
  final DateTime createdAt;

  Comment({
    required this.id,
    required this.reviewId,
    this.parentId,
    required this.userId,
    required this.userName,
    this.userPhotoUrl = '',
    required this.text,
    required this.createdAt,
  });

  bool get isReply => parentId != null;

  factory Comment.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Comment(
      id: doc.id,
      reviewId: data['reviewId'] ?? '',
      parentId: data['parentId'],
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? 'Anonim',
      userPhotoUrl: data['userPhotoUrl'] ?? '',
      text: data['text'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'reviewId': reviewId,
      'parentId': parentId,
      'userId': userId,
      'userName': userName,
      'userPhotoUrl': userPhotoUrl,
      'text': text,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}