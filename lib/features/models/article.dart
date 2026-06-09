import 'package:cloud_firestore/cloud_firestore.dart';

/// Career guide article stored at `articles/{id}`.
class Article {
  final String id;
  final String title;
  final String content;
  final String category;
  final String experienceLevel;
  final String bannerUrl;
  final String youtubeVideoId;
  final String authorName;
  final bool isFeatured;
  final bool isPublished;
  final int readTimeMinutes;
  final int viewCount;
  final DateTime createdAt;

  Article({
    required this.id,
    required this.title,
    required this.content,
    required this.category,
    required this.experienceLevel,
    required this.bannerUrl,
    required this.youtubeVideoId,
    required this.authorName,
    required this.isFeatured,
    required this.isPublished,
    required this.readTimeMinutes,
    required this.viewCount,
    required this.createdAt,
  });

  bool get hasVideo => youtubeVideoId.isNotEmpty;

  factory Article.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return Article(
      id: doc.id,
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      category: data['category'] ?? '',
      experienceLevel: data['experienceLevel'] ?? '',
      bannerUrl: data['bannerUrl'] ?? '',
      youtubeVideoId: data['youtubeVideoId'] ?? '',
      authorName: data['authorName'] ?? 'CareerCompass',
      isFeatured: data['isFeatured'] ?? false,
      isPublished: data['isPublished'] ?? false,
      readTimeMinutes: data['readTimeMinutes'] ?? 1,
      viewCount: data['viewCount'] ?? 0,
      // createdAt may be null briefly while the server timestamp resolves.
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
