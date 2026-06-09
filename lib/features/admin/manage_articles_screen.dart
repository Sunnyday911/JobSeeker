import 'package:flutter/material.dart';
import 'package:jobseeker/features/admin/article_form_screen.dart';
import 'package:jobseeker/features/models/article.dart';
import 'package:jobseeker/features/repositories/article_repository.dart';

/// Admin list of every article with edit/delete and a draft/published badge
/// (US07.5).
class ManageArticlesScreen extends StatelessWidget {
  ManageArticlesScreen({super.key});

  final _articleRepo = ArticleRepository();

  Future<void> _confirmDelete(BuildContext context, Article a) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Artikel'),
        content: Text('Hapus "${a.title}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Hapus')),
        ],
      ),
    );
    if (ok == true) await _articleRepo.delete(a.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kelola Artikel')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ArticleFormScreen()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Artikel Baru'),
      ),
      body: StreamBuilder<List<Article>>(
        stream: _articleRepo.watchAll(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final articles = snap.data ?? [];
          if (articles.isEmpty) {
            return const Center(child: Text('Belum ada artikel.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: articles.length,
            separatorBuilder: (_, _) => const Divider(),
            itemBuilder: (context, i) {
              final a = articles[i];
              return ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(a.title,
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: a.isPublished
                            ? Colors.green.shade50
                            : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        a.isPublished ? 'Published' : 'Draft',
                        style: TextStyle(
                            fontSize: 11,
                            color: a.isPublished
                                ? Colors.green.shade700
                                : Colors.grey.shade700),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(a.category,
                        style: const TextStyle(fontSize: 12)),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ArticleFormScreen(existing: a),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline,
                          color: Colors.red),
                      onPressed: () => _confirmDelete(context, a),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
