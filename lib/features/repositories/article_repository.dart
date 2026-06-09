import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:jobseeker/features/models/article.dart';

/// CRUD + queries for the `articles` collection (US04, US05, US07).
class ArticleRepository {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('articles');

  /// Estimates reading time from word count at ~200 wpm, minimum 1 minute
  /// (US07.3).
  static int estimateReadTime(String content) {
    final words = content.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
    final minutes = (words.length / 200).ceil();
    return minutes < 1 ? 1 : minutes;
  }

  /// Live feed of published articles, optionally filtered by category and/or
  /// experience level (US04). Ordering/filtering is done client-side to avoid
  /// requiring composite Firestore indexes.
  Stream<List<Article>> watchPublished({String? category, String? level}) {
    return _col.where('isPublished', isEqualTo: true).snapshots().map((snap) {
      var items = snap.docs.map(Article.fromFirestore).toList();
      if (category != null && category != 'All') {
        items = items.where((a) => a.category == category).toList();
      }
      if (level != null) {
        items = items.where((a) => a.experienceLevel == level).toList();
      }
      // Featured first, then newest.
      items.sort((a, b) {
        if (a.isFeatured != b.isFeatured) return a.isFeatured ? -1 : 1;
        return b.createdAt.compareTo(a.createdAt);
      });
      return items;
    });
  }

  /// All articles authored in the system, newest first (admin manage view, US07.5).
  Stream<List<Article>> watchAll() {
    return _col.orderBy('createdAt', descending: true).snapshots().map(
          (snap) => snap.docs.map(Article.fromFirestore).toList(),
        );
  }

  Future<Article?> getById(String id) async {
    final snap = await _col.doc(id).get();
    if (!snap.exists) return null;
    return Article.fromFirestore(snap);
  }

  /// Up to 3 other published articles in the same category (US05.6).
  Future<List<Article>> getRelated(Article article) async {
    final snap = await _col
        .where('isPublished', isEqualTo: true)
        .where('category', isEqualTo: article.category)
        .limit(4)
        .get();
    return snap.docs
        .map(Article.fromFirestore)
        .where((a) => a.id != article.id)
        .take(3)
        .toList();
  }

  /// Increments the view counter when an article is opened (US05.7).
  Future<void> incrementViewCount(String id) async {
    await _col.doc(id).update({'viewCount': FieldValue.increment(1)});
  }

  /// Creates a new article. Read time is computed from the content (US07.3/07.4).
  Future<void> create({
    required String title,
    required String content,
    required String category,
    required String experienceLevel,
    required String bannerUrl,
    required String youtubeVideoId,
    required bool isFeatured,
    required bool isPublished,
  }) async {
    await _col.add({
      'title': title,
      'content': content,
      'category': category,
      'experienceLevel': experienceLevel,
      'bannerUrl': bannerUrl,
      'youtubeVideoId': youtubeVideoId,
      'authorName': _auth.currentUser?.email ?? 'Admin',
      'isFeatured': isFeatured,
      'isPublished': isPublished,
      'readTimeMinutes': estimateReadTime(content),
      'viewCount': 0,
      'createdAt': FieldValue.serverTimestamp(),
    });
    // NOTE (US07.6): publishing should notify the 'new_articles' FCM topic.
    // Sending to a topic requires server credentials (a Cloud Function), so it
    // is intentionally not done here. Deferred.
  }

  Future<void> update({
    required String id,
    required String title,
    required String content,
    required String category,
    required String experienceLevel,
    required String bannerUrl,
    required String youtubeVideoId,
    required bool isFeatured,
    required bool isPublished,
  }) async {
    await _col.doc(id).update({
      'title': title,
      'content': content,
      'category': category,
      'experienceLevel': experienceLevel,
      'bannerUrl': bannerUrl,
      'youtubeVideoId': youtubeVideoId,
      'isFeatured': isFeatured,
      'isPublished': isPublished,
      'readTimeMinutes': estimateReadTime(content),
    });
  }

  Future<void> delete(String id) async {
    await _col.doc(id).delete();
  }
}
