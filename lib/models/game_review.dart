import 'package:cloud_firestore/cloud_firestore.dart';

class GameReview {
  final String id;
  final String title;
  final String reviewText;
  final String genre;
  final List<String> tags;
  final double rating;
  final String imageUrl;
  final String userId;
  final String userName;
  final String userPhotoUrl;
  final DateTime createdAt;
  final double? latitude;
  final double? longitude;
  final String? locationName;
  int likesCount;
  int commentsCount;

  GameReview({
    required this.id,
    required this.title,
    required this.reviewText,
    required this.genre,
    this.tags = const [],
    required this.rating,
    required this.imageUrl,
    required this.userId,
    required this.userName,
    this.userPhotoUrl = '',
    required this.createdAt,
    this.latitude,
    this.longitude,
    this.locationName,
    this.likesCount = 0,
    this.commentsCount = 0,
  });

  factory GameReview.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return GameReview(
      id: doc.id,
      title: data['title'] ?? '',
      reviewText: data['reviewText'] ?? '',
      genre: data['genre'] ?? 'Other',
      tags: List<String>.from(data['tags'] ?? []),
      rating: (data['rating'] ?? 0).toDouble(),
      imageUrl: data['imageUrl'] ?? '',
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? 'Anonim',
      userPhotoUrl: data['userPhotoUrl'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      latitude: data['latitude']?.toDouble(),
      longitude: data['longitude']?.toDouble(),
      locationName: data['locationName'],
      likesCount: data['likesCount'] ?? 0,
      commentsCount: data['commentsCount'] ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'reviewText': reviewText,
      'genre': genre,
      'tags': tags,
      'rating': rating,
      'imageUrl': imageUrl,
      'userId': userId,
      'userName': userName,
      'userPhotoUrl': userPhotoUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'latitude': latitude,
      'longitude': longitude,
      'locationName': locationName,
      'likesCount': likesCount,
      'commentsCount': commentsCount,
    };
  }
}