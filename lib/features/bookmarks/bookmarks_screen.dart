import 'package:flutter/material.dart';
import 'package:jobseeker/features/articles/widgets/article_card.dart';
import 'package:jobseeker/features/models/article.dart';
import 'package:jobseeker/features/repositories/bookmark_repository.dart';

/// Lists saved articles with swipe-to-delete and an empty state (US06.4-06.6).
class BookmarksScreen extends StatelessWidget {
  BookmarksScreen({super.key});

  final _bookmarkRepo = BookmarkRepository();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tersimpan',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: StreamBuilder<List<Article>>(
        stream: _bookmarkRepo.watchBookmarkedArticles(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final articles = snap.data ?? [];
          if (articles.isEmpty) {
            // Empty state (US06.6).
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bookmark_border, size: 64, color: Colors.grey),
                  SizedBox(height: 12),
                  Text('Belum ada artikel tersimpan.',
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              for (final article in articles)
                Dismissible(
                  key: ValueKey(article.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20, bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade400,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    margin: const EdgeInsets.only(bottom: 12),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  // Swipe to remove (US06.5).
                  onDismissed: (_) => _bookmarkRepo.remove(article.id),
                  child: ArticleCard(article: article),
                ),
            ],
          );
        },
      ),
    );
  }
}
