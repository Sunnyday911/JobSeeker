import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:jobseeker/features/models/news_article.dart';

/// Fetches industry headlines from NewsAPI.org (US08).
///
/// The free NewsAPI tier is development-only (localhost/mobile, ~100 req/day,
/// no production/CORS). For production the key should be injected via
/// `--dart-define` rather than hard-coded.
class NewsService {
  NewsService._();
  static final NewsService instance = NewsService._();

  static const String _apiKey = '7c24ea6e9fc34d969c6e8e4c63c81580';
  static const String _endpoint =
      'https://newsapi.org/v2/top-headlines?country=us&category=business&pageSize=10';

  // In-memory cache to respect the 1-hour rule (US08.5) and save quota.
  List<NewsArticle>? _cache;
  DateTime? _fetchedAt;
  static const Duration _ttl = Duration(hours: 1);

  Future<List<NewsArticle>> fetchHeadlines() async {
    final cached = _cache;
    final at = _fetchedAt;
    if (cached != null && at != null && DateTime.now().difference(at) < _ttl) {
      return cached;
    }

    final res = await http.get(
      Uri.parse(_endpoint),
      headers: {'X-Api-Key': _apiKey},
    );
    if (res.statusCode != 200) {
      // On error, fall back to any stale cache rather than throwing in the UI.
      if (cached != null) return cached;
      throw Exception('NewsAPI error ${res.statusCode}');
    }

    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final articles = (body['articles'] as List<dynamic>? ?? [])
        .map((j) => NewsArticle.fromJson(j as Map<String, dynamic>))
        .where((n) => n.title.isNotEmpty && n.title != '[Removed]')
        .toList();

    _cache = articles;
    _fetchedAt = DateTime.now();
    return articles;
  }
}
