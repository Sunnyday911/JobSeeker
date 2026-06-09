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
    required this.upvotes,
    required this.replyCount,
    required this.createdAt,
  });

  factory Question.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;

    return Question(
      id: doc.id,
      title: data['title'],
      content: data['content'],
      category: data['category'],
      authorId: data['authorId'],
      authorName: data['authorName'],
      isAnonymous: data['isAnonymous'],
      upvotes: data['upvotes'],
      replyCount: data['replyCount'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }
}