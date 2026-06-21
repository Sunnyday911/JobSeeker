import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:jobseeker/core/constants.dart';
import 'package:jobseeker/features/models/application.dart';
import 'package:jobseeker/features/repositories/application_repository.dart';
import 'package:jobseeker/features/applications/apply_form_screen.dart';
import 'package:jobseeker/features/articles/articles_feed_screen.dart';

/// Application detail (US13): status dropdown + history + notes, plus edit and
/// delete. Streams the single doc so status changes reflect live.
class ApplicationDetailScreen extends StatelessWidget {
  final String applicationId;
  const ApplicationDetailScreen({super.key, required this.applicationId});

  @override
  Widget build(BuildContext context) {
    final repo = ApplicationRepository();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Lamaran'),
      ),
      body: StreamBuilder<List<Application>>(
        stream: repo.watchMyApplications(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final app = (snap.data ?? [])
              .where((a) => a.id == applicationId)
              .cast<Application?>()
              .firstWhere((a) => a != null, orElse: () => null);
          if (app == null) {
            return const Center(child: Text('Lamaran tidak ditemukan.'));
          }
          return _body(context, repo, app);
        },
      ),
    );
  }

  Widget _body(
      BuildContext context, ApplicationRepository repo, Application app) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(app.jobTitle,
            style: theme.textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.bold)),
        Text(app.company, style: TextStyle(color: theme.colorScheme.primary)),
        const SizedBox(height: 16),

        // Status dropdown (US13.1/13.2)
        Text('Status', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue:
              kApplicationStatuses.contains(app.status) ? app.status : null,
          isExpanded: true,
          decoration: const InputDecoration(border: OutlineInputBorder()),
          items: kApplicationStatuses
              .map((s) => DropdownMenuItem(value: s, child: Text(s)))
              .toList(),
          onChanged: (v) {
            if (v != null && v != app.status) repo.updateStatus(app.id, v);
          },
        ),
        const SizedBox(height: 16),

        // Contextual link into Articles: prep content when at Interview stage.
        if (app.status == 'Interview') ...[
          OutlinedButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    const ArticlesFeedScreen(initialCategory: 'Interview Prep'),
              ),
            ),
            icon: const Icon(Icons.menu_book_outlined),
            label: const Text('Persiapan Interview'),
          ),
          const SizedBox(height: 16),
        ],

        _infoTile('Nama', app.fullName),
        _infoTile('Tanggal Lahir', app.dateOfBirth),
        _infoTile('Alamat', app.address),
        _infoTile('Telepon', app.phone),
        if (app.appliedAt != null)
          _infoTile('Tanggal Melamar',
              DateFormat('d MMM yyyy').format(app.appliedAt!)),
        if (app.notes.isNotEmpty) _infoTile('Catatan', app.notes),

        const Divider(height: 32),
        Text('Riwayat Status', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        if (app.statusHistory.isEmpty)
          const Text('Belum ada riwayat.')
        else
          ...app.statusHistory.map((h) => ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.timeline, size: 20),
                title: Text(h.status),
                subtitle: Text(DateFormat('d MMM yyyy, HH:mm').format(h.at)),
              )),

        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => ApplyFormScreen(existing: app)),
                ),
                icon: const Icon(Icons.edit),
                label: const Text('Edit'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                onPressed: () => _confirmDelete(context, repo, app.id),
                icon: const Icon(Icons.delete_outline),
                label: const Text('Hapus'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _confirmDelete(
      BuildContext context, ApplicationRepository repo, String id) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Hapus Lamaran'),
        content: const Text('Yakin ingin menghapus lamaran ini?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Batal')),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogCtx);
              await repo.deleteApplication(id);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _infoTile(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 2),
            Text(value),
          ],
        ),
      );
}
