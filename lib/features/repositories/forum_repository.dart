import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:jobseeker/features/models/question.dart';
import 'package:jobseeker/features/models/reply.dart';
import 'package:jobseeker/features/notifications/notification_service.dart';

class ForumRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _questionsCollection =>
      _firestore.collection('questions');

  Stream<List<Question>> getQuestions() {
    return _questionsCollection
        .orderBy('createdAt', descending: true)
        .limit(20)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
          .map((doc) => Question.fromFirestore(doc))
          .toList(),
    );
  }

  Future<void> createQuestion(Question question) async {
    await _questionsCollection.add(question.toJson());
  }

  Future<void> updateQuestion(
      String questionId,
      Map<String, dynamic> data,
      ) async {
    await _questionsCollection.doc(questionId).update(data);
  }

  Future<void> deleteQuestion(String questionId) async {
    await _questionsCollection.doc(questionId).delete();
  }

  Stream<List<Reply>> getReplies(String questionId) {
    return _questionsCollection
        .doc(questionId)
        .collection('replies')
        .orderBy('createdAt')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
          .map((doc) => Reply.fromFirestore(doc))
          .toList(),
    );
  }

  Future<void> addReply(String questionId, Reply reply) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;

      final questionRef = _questionsCollection.doc(questionId);
      final replyRef = questionRef.collection('replies').doc();

      // Get question owner
      final questionDoc = await questionRef.get();

      if (questionDoc.exists && currentUser != null) {
        final data = questionDoc.data();
        final authorId = data?['authorId'];

        if (authorId != null) {
          final isSelf = authorId == currentUser.uid;

          final body = isSelf
              ? 'You replied to your own question'
              : '${currentUser.displayName ?? "Someone"} replied to your question';

          await _firestore
              .collection('users')
              .doc(authorId)
              .collection('notifications')
              .add({
            'title': 'New Reply',
            'body': body,
            'createdAt': Timestamp.now(),
            'read': false,
            'route': 'forum',
          });

          await NotificationService.instance.showLocalNotification(
            title: 'New Reply',
            body: body,
            route: 'notifications',
          );
        }
      }

      await _firestore.runTransaction((transaction) async {
        transaction.set(replyRef, reply.toJson());

        transaction.update(questionRef, {
          'replyCount': FieldValue.increment(1),
        });
      });
    } catch (e) {
      throw Exception('Failed to add reply: $e');
    }
  }

  Future<void> deleteReply(String questionId, String replyId) async {
    try {
      final questionRef = _questionsCollection.doc(questionId);
      final replyRef = questionRef.collection('replies').doc(replyId);

      await _firestore.runTransaction((transaction) async {
        transaction.delete(replyRef);

        transaction.update(questionRef, {
          'replyCount': FieldValue.increment(-1),
        });
      });
    } catch (e) {
      throw Exception('Failed to delete reply: $e');
    }
  }

  Future<void> upvoteQuestion(String questionId) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      final questionRef = _questionsCollection.doc(questionId);
      final questionDoc = await questionRef.get();
      final data = questionDoc.data();
      final authorId = data?['authorId'];

      if (authorId != null && currentUser != null) {
        final isSelf = authorId == currentUser.uid;

        final body = isSelf
            ? 'You liked your own question'
            : '${currentUser.displayName ?? "Someone"} liked your question';

        await _firestore
            .collection('users')
            .doc(authorId)
            .collection('notifications')
            .add({
          'title': 'Question Liked',
          'body': body,
          'createdAt': Timestamp.now(),
          'read': false,
          'route': 'forum',
        });

        await NotificationService.instance.showLocalNotification(
          title: 'Question Liked',
          body: body,
          route: 'notifications',
        );
      }

      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(questionRef);

        if (!snapshot.exists) {
          throw Exception('Question does not exist!');
        }

        final currentUpvotes = (snapshot.data()?['upvotes'] ?? 0) as int;

        transaction.update(questionRef, {
          'upvotes': currentUpvotes + 1,
        });
      });
    } catch (e) {
      throw Exception('Failed to upvote question: $e');
    }
  }
}