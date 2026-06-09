import 'package:cloud_firestore/cloud_firestore.dart';

class Question {
  final String id;
  final String title;
  final String content;
  final String category;
  final String authorId;
  final String authorName;
  final bool isAnonymous;
  final int upvotes;
  final int replyCount;
  final DateTime createdAt;

  Question({
    required this.id,
    required this.title,
    required this.content,
    required this.category,
    required this.authorId,
    required this.authorName,
    required this.isAnonymous,
    this.upvotes = 0,
    this.replyCount = 0,
    required this.createdAt,
  });

  Question copyWith({
    String? id,
    String? title,
    String? content,
    String? category,
    String? authorId,
    String? authorName,
    bool? isAnonymous,
    int? upvotes,
    int? replyCount,
    DateTime? createdAt,
  }) {
    return Question(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      category: category ?? this.category,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      upvotes: upvotes ?? this.upvotes,
      replyCount: replyCount ?? this.replyCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory Question.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Question(
      id: doc.id,
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      category: data['category'] ?? '',
      authorId: data['authorId'] ?? '',
      authorName: data['authorName'] ?? '',
      isAnonymous: data['isAnonymous'] ?? false,
      upvotes: data['upvotes'] ?? 0,
      replyCount: data['replyCount'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'content': content,
      'category': category,
      'authorId': authorId,
      'authorName': authorName,
      'isAnonymous': isAnonymous,
      'upvotes': upvotes,
      'replyCount': replyCount,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
