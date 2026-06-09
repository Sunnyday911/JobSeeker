import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:jobseeker/features/models/article.dart';

/// Manages bookmarks stored under `users/{uid}/bookmarks/{articleId}` (US06).
class BookmarkRepository {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _col => _db
      .collection('users')
      .doc(_auth.currentUser!.uid)
      .collection('bookmarks');

  /// Live status of whether an article is bookmarked (drives the icon, US06.2).
  Stream<bool> watchIsBookmarked(String articleId) {
    return _col.doc(articleId).snapshots().map((snap) => snap.exists);
  }

  /// Adds or removes a bookmark (US06.1/06.3/06.5).
  Future<void> toggle(String articleId) async {
    final ref = _col.doc(articleId);
    final snap = await ref.get();
    if (snap.exists) {
      await ref.delete();
    } else {
      await ref.set({
        'articleId': articleId,
        'savedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> remove(String articleId) async {
    await _col.doc(articleId).delete();
  }

  /// Resolves the saved bookmark ids into full articles, newest-saved first
  /// (US06.4). Articles that were since deleted are skipped.
  Stream<List<Article>> watchBookmarkedArticles() {
    return _col.orderBy('savedAt', descending: true).snapshots().asyncMap(
      (snap) async {
        final articles = <Article>[];
        for (final doc in snap.docs) {
          final articleSnap =
              await _db.collection('articles').doc(doc.id).get();
          if (articleSnap.exists) {
            articles.add(Article.fromFirestore(articleSnap));
          }
        }
        return articles;
      },
    );
  }
}
