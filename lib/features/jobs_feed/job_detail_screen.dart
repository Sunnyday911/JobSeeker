import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:jobseeker/features/models/job.dart';
import 'package:jobseeker/features/repositories/saved_job_repository.dart';
import 'package:jobseeker/features/applications/apply_form_screen.dart';

/// Full Adzuna job detail (US06): info, save toggle (US07), and an external
/// "Lamar Sekarang" link to the original posting.
class JobDetailScreen extends StatelessWidget {
  final Job job;
  const JobDetailScreen({super.key, required this.job});

  Future<void> _openOriginal(BuildContext context) async {
    final url = job.redirectUrl;
    if (url == null || url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tautan lowongan tidak tersedia.')),
      );
      return;
    }
    final ok =
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak dapat membuka tautan.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final savedRepo = SavedJobRepository();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Lowongan'),
        actions: [
          StreamBuilder<bool>(
            stream: savedRepo.watchIsSaved(job.id),
            builder: (context, snap) {
              final saved = snap.data ?? false;
              return IconButton(
                tooltip: saved ? 'Hapus dari tersimpan' : 'Simpan Lowongan',
                icon: Icon(saved ? Icons.bookmark : Icons.bookmark_border),
                onPressed: () async {
                  await savedRepo.toggle(job);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(saved
                            ? 'Lowongan dihapus dari tersimpan'
                            : 'Lowongan disimpan'),
                      ),
                    );
                  }
                },
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(job.title,
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(job.company,
              style: theme.textTheme.titleMedium
                  ?.copyWith(color: theme.colorScheme.primary)),
          const SizedBox(height: 16),
          _infoRow(Icons.location_on_outlined, job.location),
          _infoRow(Icons.payments_outlined, job.salaryRange),
          if (job.category != null)
            _infoRow(Icons.category_outlined, job.category!),
          if (job.created != null)
            _infoRow(Icons.calendar_today_outlined,
                'Diposting ${DateFormat('d MMM yyyy').format(job.created!)}'),
          const Divider(height: 32),
          Text('Deskripsi Pekerjaan',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            job.description.isEmpty ? 'Tidak ada deskripsi.' : job.description,
            style: const TextStyle(height: 1.5),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => _openOriginal(context),
            icon: const Icon(Icons.open_in_new),
            label: const Text('Lamar Sekarang'),
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ApplyFormScreen(job: job)),
            ),
            icon: const Icon(Icons.assignment_outlined),
            label: const Text('Catat Lamaran'),
            style:
                OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Icon(icon, size: 18, color: Colors.grey),
            const SizedBox(width: 8),
            Expanded(child: Text(text)),
          ],
        ),
      );
}
