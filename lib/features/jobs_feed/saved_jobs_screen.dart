import 'package:flutter/material.dart';
import 'package:jobseeker/features/models/job.dart';
import 'package:jobseeker/features/repositories/saved_job_repository.dart';
import 'package:jobseeker/features/jobs_feed/job_detail_screen.dart';

/// "Tersimpan" page — all saved jobs with swipe-to-delete (US07.4/07.5/07.6).
class SavedJobsScreen extends StatelessWidget {
  const SavedJobsScreen({super.key});

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
                    title: Text(job.title,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${job.company} • ${job.location}'),
                    trailing: const Icon(Icons.chevron_right),
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
