import 'package:flutter/material.dart';
import 'package:jobseeker/core/constants.dart';
import 'package:jobseeker/features/models/article.dart';
import 'package:jobseeker/features/repositories/article_repository.dart';

/// Create or edit an article (US07.2-07.5). Read time is computed automatically
/// from the content word count on save.
class ArticleFormScreen extends StatefulWidget {
  /// When non-null the form edits an existing article; otherwise it creates one.
  final Article? existing;
  const ArticleFormScreen({super.key, this.existing});

  @override
  State<ArticleFormScreen> createState() => _ArticleFormScreenState();
}

class _ArticleFormScreenState extends State<ArticleFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _articleRepo = ArticleRepository();

  late final TextEditingController _title;
  late final TextEditingController _content;
  late final TextEditingController _banner;
  late final TextEditingController _videoId;

  late String _category;
  late String _level;
  late bool _isFeatured;
  bool _isSaving = false;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final a = widget.existing;
    _title = TextEditingController(text: a?.title ?? '');
    _content = TextEditingController(text: a?.content ?? '');
    _banner = TextEditingController(text: a?.bannerUrl ?? '');
    _videoId = TextEditingController(text: a?.youtubeVideoId ?? '');
    _category = a?.category ?? kArticleCategories.first;
    _level = a?.experienceLevel ?? kExperienceLevels.first;
    _isFeatured = a?.isFeatured ?? false;
  }

  @override
  void dispose() {
    _title.dispose();
    _content.dispose();
    _banner.dispose();
    _videoId.dispose();
    super.dispose();
  }

  Future<void> _save({required bool publish}) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      if (_isEditing) {
        await _articleRepo.update(
          id: widget.existing!.id,
          title: _title.text.trim(),
          content: _content.text.trim(),
          category: _category,
          experienceLevel: _level,
          bannerUrl: _banner.text.trim(),
          youtubeVideoId: _videoId.text.trim(),
          isFeatured: _isFeatured,
          isPublished: publish,
        );
      } else {
        await _articleRepo.create(
          title: _title.text.trim(),
          content: _content.text.trim(),
          category: _category,
          experienceLevel: _level,
          bannerUrl: _banner.text.trim(),
          youtubeVideoId: _videoId.text.trim(),
          isFeatured: _isFeatured,
          isPublished: publish,
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(publish ? 'Artikel dipublikasikan.' : 'Draft disimpan.')),
      );
      Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal menyimpan artikel.')),
        );
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text(_isEditing ? 'Edit Artikel' : 'Artikel Baru')),
      body: AbsorbPointer(
        absorbing: _isSaving,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextFormField(
                controller: _title,
                decoration: const InputDecoration(
                    labelText: 'Judul', border: OutlineInputBorder()),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: const InputDecoration(
                    labelText: 'Kategori', border: OutlineInputBorder()),
                items: kArticleCategories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => _category = v!),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _level,
                decoration: const InputDecoration(
                    labelText: 'Level Pengalaman',
                    border: OutlineInputBorder()),
                items: kExperienceLevels
                    .map((l) => DropdownMenuItem(value: l, child: Text(l)))
                    .toList(),
                onChanged: (v) => setState(() => _level = v!),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _banner,
                decoration: const InputDecoration(
                    labelText: 'URL Banner (opsional)',
                    border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _videoId,
                decoration: const InputDecoration(
                    labelText: 'YouTube Video ID (opsional)',
                    helperText: 'Mis. dQw4w9WgXcQ',
                    border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _content,
                maxLines: 10,
                decoration: const InputDecoration(
                    labelText: 'Isi Artikel',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder()),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                value: _isFeatured,
                onChanged: (v) => setState(() => _isFeatured = v),
                title: const Text('Tandai sebagai Featured'),
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _save(publish: false),
                      style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(48)),
                      child: const Text('Simpan Draft'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => _save(publish: true),
                      style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(48)),
                      child: _isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2))
                          : const Text('Publikasikan'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
