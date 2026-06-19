import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jobseeker/features/models/question.dart';
import 'package:jobseeker/features/models/reply.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ForumRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Questions Collection
  CollectionReference<Map<String, dynamic>> get _questionsCollection =>
      _firestore.collection('questions');

  // Stream of latest 20 questions
  Stream<List<Question>> getQuestions() {
    return _questionsCollection
        .orderBy('createdAt', descending: true)
        .limit(20)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Question.fromFirestore(doc)).toList();
    });
  }

  // Create a new question
  Future<void> createQuestion(Question question) async {
    try {
      await _questionsCollection.add(question.toJson());
    } catch (e) {
      throw Exception('Failed to create question: $e');
    }
  }

  // Update a question
  Future<void> updateQuestion(String questionId, Map<String, dynamic> data) async {
    try {
      await _questionsCollection.doc(questionId).update(data);
    } catch (e) {
      throw Exception('Failed to update question: $e');
    }
  }

  // Delete a question
  Future<void> deleteQuestion(String questionId) async {
    try {
      await _questionsCollection.doc(questionId).delete();
    } catch (e) {
      throw Exception('Failed to delete question: $e');
    }
  }

  // Stream of replies for a specific question
  Stream<List<Reply>> getReplies(String questionId) {
    return _questionsCollection
        .doc(questionId)
        .collection('replies')
        .orderBy('createdAt', descending: false)
        .limit(20)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Reply.fromFirestore(doc)).toList();
    });
  }

  // Add a reply and increment replyCount
  Future<void> addReply(String questionId, Reply reply) async {
    try {
      final questionRef = _questionsCollection.doc(questionId);
      final replyRef = questionRef.collection('replies').doc();

      final currentUser = FirebaseAuth.instance.currentUser;

      final questionDoc = await questionRef.get();

      if (questionDoc.exists &&
          currentUser != null) {

        final questionData = questionDoc.data();
        final authorId = questionData?['authorId'];

        if (authorId != null &&
            authorId != currentUser.uid) {

          await _firestore
              .collection('users')
              .doc(authorId)
              .collection('notifications')
              .add({
            'title': 'New Reply',
            'body':
            '${currentUser.displayName ?? "Someone"} replied to your question',
            'createdAt': Timestamp.now(),
            'read': false,
            'route': 'forum',
          });
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

  // Delete a reply and decrement replyCount
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

  // Upvote a question using a transaction
  Future<void> upvoteQuestion(String questionId) async {
    try {
      final questionRef = _questionsCollection.doc(questionId);
      final currentUser = FirebaseAuth.instance.currentUser;

      final questionDoc =
      await FirebaseFirestore.instance
          .collection('questions')
          .doc(questionId)
          .get();

      final questionData = questionDoc.data();
      final authorId = questionData?['authorId'];

      if (authorId != null &&
          currentUser != null &&
          authorId != currentUser.uid) {

        await FirebaseFirestore.instance
            .collection('users')
            .doc(authorId)
            .collection('notifications')
            .add({
          'title': 'New Like',
          'body':
          '${currentUser.displayName ?? "Someone"} liked your post',
          'createdAt': Timestamp.now(),
          'read': false,
          'route': 'forum',
        });
      }

      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(questionRef);
        if (!snapshot.exists) {
          throw Exception("Question does not exist!");
        }

        final newUpvotes = (snapshot.data()?['upvotes'] ?? 0) + 1;
        transaction.update(questionRef, {'upvotes': newUpvotes});

      });
    } catch (e) {
      throw Exception('Failed to upvote question: $e');
    }
  }
}
