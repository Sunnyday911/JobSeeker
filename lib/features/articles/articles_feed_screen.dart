import 'package:flutter/material.dart';
import 'package:jobseeker/core/constants.dart';
import 'package:jobseeker/features/articles/widgets/article_card.dart';
import 'package:jobseeker/features/articles/widgets/news_row.dart';
import 'package:jobseeker/features/models/app_user.dart';
import 'package:jobseeker/features/models/article.dart';
import 'package:jobseeker/features/repositories/article_repository.dart';
import 'package:jobseeker/features/repositories/user_repository.dart';

/// Main feed: industry news (US08) + filterable article list (US04).
class ArticlesFeedScreen extends StatefulWidget {
  final String? initialCategory;
  const ArticlesFeedScreen({super.key, this.initialCategory});

  @override
  State<ArticlesFeedScreen> createState() => _ArticlesFeedScreenState();
}

class _ArticlesFeedScreenState extends State<ArticlesFeedScreen> {
  final _articleRepo = ArticleRepository();
  final _userRepo = UserRepository();

  String _category = 'All';
  bool _matchMyLevel = false;
  AppUser? _profile;

  @override
  void initState() {
    super.initState();
    if (widget.initialCategory != null) _category = widget.initialCategory!;
    _userRepo.getCurrentProfile().then((p) {
      if (mounted) setState(() => _profile = p);
    });
  }

  @override
  Widget build(BuildContext context) {
    final categories = ['All', ...kArticleCategories];
    final levelFilter =
        _matchMyLevel ? _profile?.experienceLevel : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('CareerCompass',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          // Category filter chips (US04.2) + level toggle (US04.3).
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                for (final c in categories)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 4, vertical: 8),
                    child: ChoiceChip(
                      label: Text(c),
                      selected: _category == c,
                      onSelected: (_) => setState(() => _category = c),
                    ),
                  ),
              ],
            ),
          ),
          if (_profile?.experienceLevel != null)
            SwitchListTile(
              value: _matchMyLevel,
              onChanged: (v) => setState(() => _matchMyLevel = v),
              dense: true,
              title: Text(
                'Sesuai level saya (${_profile!.experienceLevel})',
                style: const TextStyle(fontSize: 13),
              ),
            ),
          Expanded(
            child: StreamBuilder<List<Article>>(
              stream: _articleRepo.watchPublished(
                category: _category,
                level: levelFilter,
              ),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final articles = snap.data ?? [];
                return ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    const NewsRow(),
                    const SizedBox(height: 8),
                    const Text('Artikel Panduan Karir',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    if (articles.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 48),
                        child: Center(
                          child: Text('Belum ada artikel untuk filter ini.'),
                        ),
                      )
                    else
                      ...articles.map((a) => ArticleCard(article: a)),
                    const SizedBox(height: 16),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
