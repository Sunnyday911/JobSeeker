import 'package:flutter/material.dart';
import 'package:jobseeker/features/models/news_article.dart';
import 'package:jobseeker/features/services/news_service.dart';
import 'package:url_launcher/url_launcher.dart';

/// Horizontal industry-news strip shown at the top of the feed (US08).
class NewsRow extends StatefulWidget {
  const NewsRow({super.key});

  @override
  State<NewsRow> createState() => _NewsRowState();
}

class _NewsRowState extends State<NewsRow> {
  late Future<List<NewsArticle>> _future;

  @override
  void initState() {
    super.initState();
    _future = NewsService.instance.fetchHeadlines();
  }

  Future<void> _open(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    // Opens the full article in the browser (US08.4).
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<NewsArticle>>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 180,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (snap.hasError || (snap.data?.isEmpty ?? true)) {
          // News is non-critical; fail quietly so the article feed still works.
          return const SizedBox.shrink();
        }
        final news = snap.data!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Text('Berita Industri Terkini',
                  style:
                      TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            SizedBox(
              height: 170,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: news.length,
                itemBuilder: (context, i) => _NewsCard(
                  news: news[i],
                  onTap: () => _open(news[i].url),
                ),
              ),
            ),
            // Mandatory attribution (US08.6).
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 6, 16, 8),
              child: Text('Powered by NewsAPI.org',
                  style: TextStyle(fontSize: 11, color: Colors.grey)),
            ),
          ],
        );
      },
    );
  }
}

class _NewsCard extends StatelessWidget {
  final NewsArticle news;
  final VoidCallback onTap;
  const _NewsCard({required this.news, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 220,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
              child: news.imageUrl.isNotEmpty
                  ? Image.network(
                      news.imageUrl,
                      height: 90,
                      width: 220,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => _placeholder(),
                    )
                  : _placeholder(),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(news.source,
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700)),
                  const SizedBox(height: 4),
                  Text(news.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
        height: 90,
        width: 220,
        color: Colors.grey.shade200,
        child: const Icon(Icons.article_outlined, color: Colors.grey),
      );
}
