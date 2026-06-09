Stream<List<Question>> getQuestions() {
  return FirebaseFirestore.instance
      .collection('questions')
      .orderBy('createdAt', descending: true)
      .limit(20)
      .snapshots()
      .map((snapshot) =>
      snapshot.docs.map(Question.fromFirestore).toList());
}

Future<void> createQuestion({
  required String title,
  required String content,
  required String category,
  required bool anonymous,
}) async {
  final user = FirebaseAuth.instance.currentUser!;

  await FirebaseFirestore.instance
      .collection('questions')
      .add({
    'title': title,
    'content': content,
    'category': category,
    'authorId': user.uid,
    'authorName': user.displayName ?? 'User',
    'isAnonymous': anonymous,
    'upvotes': 0,
    'replyCount': 0,
    'createdAt': FieldValue.serverTimestamp(),
  });
}

Future<void> addReply({
  required String questionId,
  required String content,
}) async {

  final user = FirebaseAuth.instance.currentUser!;

  final questionRef = FirebaseFirestore.instance
      .collection('questions')
      .doc(questionId);

  await questionRef
      .collection('replies')
      .add({
    'content': content,
    'authorId': user.uid,
    'authorName': user.displayName,
    'createdAt': FieldValue.serverTimestamp(),
  });

  await questionRef.update({
    'replyCount': FieldValue.increment(1),
  });
}