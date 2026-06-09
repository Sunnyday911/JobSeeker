import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:jobseeker/features/models/article.dart';
import 'package:jobseeker/features/repositories/article_repository.dart';
import 'package:jobseeker/features/repositories/bookmark_repository.dart';
import 'package:url_launcher/url_launcher.dart';

/// Full article view with YouTube tutorial, related articles, view counting
/// (US05) and a bookmark toggle (US06).
class ArticleDetailScreen extends StatefulWidget {
  final String articleId;
  const ArticleDetailScreen({super.key, required this.articleId});

  @override
  State<ArticleDetailScreen> createState() => _ArticleDetailScreenState();
}

class _ArticleDetailScreenState extends State<ArticleDetailScreen> {
  final _articleRepo = ArticleRepository();
  final _bookmarkRepo = BookmarkRepository();

  late Future<Article?> _articleFuture;
  Future<List<Article>>? _relatedFuture;

  @override
  void initState() {
    super.initState();
    _articleFuture = _load();
  }

  Future<Article?> _load() async {
    final article = await _articleRepo.getById(widget.articleId);
    if (article != null) {
      // Count the view once on open (US05.7).
      await _articleRepo.incrementViewCount(article.id);
      _relatedFuture = _articleRepo.getRelated(article);
    }
    return article;
  }

  Future<void> _openYoutube(String videoId) async {
    final uri = Uri.parse('https://www.youtube.com/watch?v=$videoId');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Artikel'),
        actions: [
          // Bookmark toggle (US06.1/06.2).
          StreamBuilder<bool>(
            stream: _bookmarkRepo.watchIsBookmarked(widget.articleId),
            builder: (context, snap) {
              final saved = snap.data ?? false;
              return IconButton(
                icon: Icon(saved ? Icons.bookmark : Icons.bookmark_border),
                onPressed: () => _bookmarkRepo.toggle(widget.articleId),
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<Article?>(
        future: _articleFuture,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final article = snap.data;
          if (article == null) {
            return const Center(child: Text('Artikel tidak ditemukan.'));
          }
          return ListView(
            children: [
              if (article.bannerUrl.isNotEmpty)
                Image.network(
                  article.bannerUrl,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    height: 200,
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.image_not_supported_outlined,
                        color: Colors.grey),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(article.title,
                        style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    // Author + publish date (US05.2).
                    Row(
                      children: [
                        const Icon(Icons.person_outline,
                            size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(article.authorName,
                            style: const TextStyle(color: Colors.grey)),
                        const SizedBox(width: 12),
                        const Icon(Icons.calendar_today_outlined,
                            size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat('d MMM yyyy').format(article.createdAt),
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text('${article.readTimeMinutes} min baca · '
                        '${article.viewCount} dilihat',
                        style: const TextStyle(
                            fontSize: 12, color: Colors.grey)),
                    const Divider(height: 28),
                    // Readable body (US05.3).
                    Text(article.content,
                        style: const TextStyle(fontSize: 15, height: 1.6)),
                    const SizedBox(height: 24),
                    // YouTube tutorial card (US05.4/05.5).
                    if (article.hasVideo)
                      _YoutubeCard(
                        onTap: () => _openYoutube(article.youtubeVideoId),
                      ),
                    const SizedBox(height: 24),
                    _RelatedSection(future: _relatedFuture),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _YoutubeCard extends StatelessWidget {
  final VoidCallback onTap;
  const _YoutubeCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.shade100),
        ),
        child: Row(
          children: [
            const Icon(Icons.play_circle_fill,
                color: Colors.red, size: 40),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Tonton Tutorial',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  Text('Buka video di YouTube',
                      style: TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
            const Icon(Icons.open_in_new, size: 18, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}

class _RelatedSection extends StatelessWidget {
  final Future<List<Article>>? future;
  const _RelatedSection({required this.future});

  @override
  Widget build(BuildContext context) {
    if (future == null) return const SizedBox.shrink();
    return FutureBuilder<List<Article>>(
      future: future,
      builder: (context, snap) {
        final related = snap.data ?? [];
        if (related.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Artikel Terkait',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...related.map(
              (a) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.article_outlined),
                title: Text(a.title,
                    maxLines: 2, overflow: TextOverflow.ellipsis),
                subtitle: Text('${a.readTimeMinutes} min baca'),
                onTap: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ArticleDetailScreen(articleId: a.id),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
