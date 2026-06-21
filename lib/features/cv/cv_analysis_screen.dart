import 'package:flutter/material.dart';
import 'package:jobseeker/core/constants.dart';
import 'package:jobseeker/features/models/cv_profile.dart';
import 'package:jobseeker/features/repositories/cv_repository.dart';
import 'package:jobseeker/features/services/claude_service.dart';

/// CV analysis with Claude (US08): paste CV → validate ≥100 chars → extract
/// editable skill chips + level + summary → save the profile (not the raw CV).
class CvAnalysisScreen extends StatefulWidget {
  const CvAnalysisScreen({super.key});

  @override
  State<CvAnalysisScreen> createState() => _CvAnalysisScreenState();
}

class _CvAnalysisScreenState extends State<CvAnalysisScreen> {
  final _cvCtrl = TextEditingController();
  final _summaryCtrl = TextEditingController();
  final _addSkillCtrl = TextEditingController();
  final _cvRepo = CvRepository();

  final List<String> _skills = [];
  String? _level;
  bool _isAnalyzing = false;
  bool _isSaving = false;
  bool _hasResult = false;

  @override
  void initState() {
    super.initState();
    _loadExisting();
  }

  Future<void> _loadExisting() async {
    final existing = await _cvRepo.getProfile();
    if (existing != null && mounted) {
      setState(() {
        _skills
          ..clear()
          ..addAll(existing.skills);
        _level = _normalizeLevel(existing.experienceLevel);
        _summaryCtrl.text = existing.summary;
        _hasResult = true;
      });
    }
  }

  @override
  void dispose() {
    _cvCtrl.dispose();
    _summaryCtrl.dispose();
    _addSkillCtrl.dispose();
    super.dispose();
  }

  String? _normalizeLevel(String raw) {
    for (final l in kExperienceLevels) {
      if (l.toLowerCase() == raw.toLowerCase()) return l;
    }
    return null;
  }

  Future<void> _analyze() async {
    final text = _cvCtrl.text.trim();
    if (text.length < 100) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('CV minimal 100 karakter sebelum dianalisis.')),
      );
      return;
    }
    setState(() => _isAnalyzing = true);
    try {
      final profile = await ClaudeService.instance.analyzeCv(text);
      if (!mounted) return;
      setState(() {
        _skills
          ..clear()
          ..addAll(profile.skills);
        _level = _normalizeLevel(profile.experienceLevel);
        _summaryCtrl.text = profile.summary;
        _hasResult = true;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menganalisis CV: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isAnalyzing = false);
    }
  }

  void _addSkill() {
    final s = _addSkillCtrl.text.trim();
    if (s.isEmpty) return;
    setState(() {
      _skills.add(s);
      _addSkillCtrl.clear();
    });
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      await _cvRepo.saveProfile(CvProfile(
        skills: _skills,
        experienceLevel: _level ?? '',
        summary: _summaryCtrl.text.trim(),
      ));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil CV disimpan.')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Analisis CV dengan AI')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Tempel teks CV kamu',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(
            controller: _cvCtrl,
            maxLines: 8,
            decoration: const InputDecoration(
              hintText:
                  'Tempel (paste) isi CV di sini (minimal 100 karakter)...',
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _isAnalyzing ? null : _analyze,
            icon: _isAnalyzing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.auto_awesome),
            label: Text(_isAnalyzing ? 'Menganalisis...' : 'Analisis CV'),
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
          ),
          if (_hasResult) ...[
            const Divider(height: 32),
            Text('Skill (dapat diedit)',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: _skills
                  .map((s) => Chip(
                        label: Text(s),
                        onDeleted: () => setState(() => _skills.remove(s)),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _addSkillCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Tambah skill',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onSubmitted: (_) => _addSkill(),
                  ),
                ),
                IconButton(
                    onPressed: _addSkill, icon: const Icon(Icons.add_circle)),
              ],
            ),
            const SizedBox(height: 16),
            Text('Level Pengalaman',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _level,
              isExpanded: true,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              items: kExperienceLevels
                  .map((l) => DropdownMenuItem(value: l, child: Text(l)))
                  .toList(),
              onChanged: (v) => setState(() => _level = v),
            ),
            const SizedBox(height: 16),
            Text('Ringkasan Profil',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _summaryCtrl,
              maxLines: 4,
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _isSaving ? null : _save,
              style:
                  FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
              child: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('Simpan Profil'),
            ),
          ],
        ],
      ),
    );
  }
}
