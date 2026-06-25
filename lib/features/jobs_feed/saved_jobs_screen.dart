import 'package:flutter/material.dart';
import 'package:jobseeker/features/models/job.dart';
import 'package:jobseeker/features/repositories/saved_job_repository.dart';
import 'package:jobseeker/features/jobs_feed/job_detail_screen.dart';

/// "Tersimpan" page — all saved jobs with swipe-to-delete (US07.4/07.5/07.6)
/// and a per-job editable personal note (US07 — UPDATE).
class SavedJobsScreen extends StatelessWidget {
  const SavedJobsScreen({super.key});

  Future<void> _editNote(
      BuildContext context, SavedJobRepository repo, Job job) async {
    final ctrl = TextEditingController(text: job.note ?? '');
    final note = await showDialog<String>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Catatan'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Catatan pribadi untuk lowongan ini...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Batal')),
          FilledButton(
            onPressed: () => Navigator.pop(dialogCtx, ctrl.text.trim()),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    if (note == null) return;
    await repo.updateNote(job.id, note);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Catatan disimpan')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = SavedJobRepository();
    return Scaffold(
      appBar: AppBar(title: const Text('Lowongan Tersimpan')),
      body: StreamBuilder<List<Job>>(
        stream: repo.watchSavedJobs(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final jobs = snap.data ?? [];
          if (jobs.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('Belum ada lowongan tersimpan.'),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: jobs.length,
            itemBuilder: (context, i) {
              final job = jobs[i];
              return Dismissible(
                key: Key(job.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  color: Theme.of(context).colorScheme.errorContainer,
                  child: const Icon(Icons.delete_outline),
                ),
                onDismissed: (_) async {
                  await repo.remove(job.id);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Lowongan dihapus dari tersimpan')),
                    );
                  }
                },
                child: Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    isThreeLine: job.note?.isNotEmpty ?? false,
                    title: Text(job.title,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${job.company} • ${job.location}'),
                        if (job.note?.isNotEmpty ?? false)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Row(
                              children: [
                                const Icon(Icons.sticky_note_2_outlined,
                                    size: 14, color: Colors.grey),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(job.note!,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          fontSize: 12,
                                          fontStyle: FontStyle.italic,
                                          color: Colors.grey)),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    trailing: IconButton(
                      tooltip: 'Edit catatan',
                      icon: const Icon(Icons.edit_note),
                      onPressed: () => _editNote(context, repo, job),
                    ),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => JobDetailScreen(job: job)),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
