/// A news headline returned by NewsAPI.org (US08).
class NewsArticle {
  final String title;
  final String source;
  final String url;
  final String imageUrl;

  NewsArticle({
    required this.title,
    required this.source,
    required this.url,
    required this.imageUrl,
  });

  factory NewsArticle.fromJson(Map<String, dynamic> json) {
    return NewsArticle(
      title: json['title'] ?? '',
      source: (json['source']?['name']) ?? 'Unknown',
      url: json['url'] ?? '',
      imageUrl: json['urlToImage'] ?? '',
    );
  }
}
