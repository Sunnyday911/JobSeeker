import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:jobseeker/core/constants.dart';
import 'package:jobseeker/features/models/cv_profile.dart';
import 'package:jobseeker/features/repositories/cv_repository.dart';
import 'package:jobseeker/features/services/claude_service.dart';

/// CV analysis with Claude (US08): upload a CV file (PDF/TXT) → extract text
/// client-side → validate ≥100 chars → extract editable skill chips + level +
/// summary → save the profile (never the raw CV file or its text).
class CvAnalysisScreen extends StatefulWidget {
  const CvAnalysisScreen({super.key});

  @override
  State<CvAnalysisScreen> createState() => _CvAnalysisScreenState();
}

class _CvAnalysisScreenState extends State<CvAnalysisScreen> {
  final _summaryCtrl = TextEditingController();
  final _addSkillCtrl = TextEditingController();
  final _cvRepo = CvRepository();

  final List<String> _skills = [];
  String? _level;
  String? _fileName; // name of the picked CV file (display only)
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

  /// Picks a PDF/TXT CV, extracts its text client-side (no upload), validates
  /// ≥100 chars, then runs Claude analysis. The raw file/text is never stored.
  Future<void> _pickAndAnalyze() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'txt'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return; // cancelled

    final picked = result.files.single;
    setState(() => _isAnalyzing = true);
    try {
      final bytes = picked.bytes ??
          (picked.path != null ? await File(picked.path!).readAsBytes() : null);
      if (bytes == null) {
        throw 'Tidak bisa membaca isi file.';
      }

      final ext = (picked.extension ?? '').toLowerCase();
      String text;
      if (ext == 'pdf') {
        final doc = PdfDocument(inputBytes: bytes);
        text = PdfTextExtractor(doc).extractText();
        doc.dispose();
      } else {
        text = utf8.decode(bytes, allowMalformed: true);
      }
      text = text.trim();

      if (text.length < 100) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text(
                    'Teks CV kurang dari 100 karakter. Jika ini PDF hasil scan/gambar, gunakan file PDF/TXT berbasis teks.')),
          );
        }
        return;
      }

      _fileName = picked.name;
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

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Hapus Profil CV'),
        content: const Text(
            'Profil CV dan rekomendasi yang dihasilkan akan dihapus. Lanjutkan?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogCtx, false),
              child: const Text('Batal')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await _cvRepo.deleteProfile();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil CV dihapus.')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menghapus: $e')),
        );
      }
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
          Text('Unggah file CV kamu',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('Format didukung: PDF atau TXT (berbasis teks, bukan hasil scan).',
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey)),
          const SizedBox(height: 12),
          if (_fileName != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  const Icon(Icons.insert_drive_file_outlined, size: 18),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(_fileName!,
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
            ),
          FilledButton.icon(
            onPressed: _isAnalyzing ? null : _pickAndAnalyze,
            icon: _isAnalyzing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.upload_file),
            label: Text(_isAnalyzing
                ? 'Menganalisis...'
                : (_fileName == null
                    ? 'Pilih file CV (PDF/TXT)'
                    : 'Pilih file CV lain')),
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
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _isSaving ? null : _delete,
              icon: const Icon(Icons.delete_outline),
              label: const Text('Hapus Profil CV'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                foregroundColor: Colors.red,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
