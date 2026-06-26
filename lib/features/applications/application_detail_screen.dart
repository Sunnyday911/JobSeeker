import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:jobseeker/core/constants.dart';
import 'package:jobseeker/features/models/application.dart';
import 'package:jobseeker/features/repositories/application_repository.dart';
import 'package:jobseeker/features/applications/apply_form_screen.dart';

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
        const SizedBox(height: 8),
        // Current status badge, color-coded (Change Plan 2.0, Part 9).
        Align(
          alignment: Alignment.centerLeft,
          child: Chip(
            label: Text(app.status,
                style: const TextStyle(color: Colors.white, fontSize: 12)),
            backgroundColor: applicationStatusColor(app.status),
            visualDensity: VisualDensity.compact,
          ),
        ),
        const SizedBox(height: 16),

        // Accepted → celebratory "next steps" card with company + HR name.
        if (app.status == 'Tawaran Diterima') _acceptedCard(context, app),
        // Company's accept/reject message, when present.
        if ((app.decisionNote ?? '').isNotEmpty) _decisionNoteCard(context, app),

        // Status — editable ONLY for self-tracked external applications. For a
        // company-posted job (has a company owner) the status is controlled by
        // the company, so the seeker sees it read-only.
        Text('Status', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        if (app.jobOwnerId == null)
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
          )
        else
          const Text(
            'Status lamaran ini diatur oleh perusahaan.',
            style: TextStyle(color: Colors.grey),
          ),
        const SizedBox(height: 16),

        _infoTile('Nama', app.fullName),
        _infoTile('Tanggal Lahir', app.dateOfBirth),
        _infoTile('Alamat', app.address),
        _infoTile('Telepon', app.phone),
        if (app.platform.isNotEmpty) _infoTile('Platform', app.platform),
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

  /// Celebratory "what next" card for an accepted application. Fetches the job's
  /// HR/recruiter name (`poster_name`) from `jobs/{jobId}`; falls back to the
  /// company name only if the job is missing/deleted or has no jobId.
  Widget _acceptedCard(BuildContext context, Application app) {
    final jobId = app.jobId;
    return Card(
      color: Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.celebration_outlined, color: Colors.green),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Selamat! Lamaran Anda diterima',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade800)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text('Perusahaan akan menghubungi Anda untuk langkah '
                'selanjutnya. Kontak:'),
            const SizedBox(height: 8),
            _contactRow(Icons.business_outlined, 'Perusahaan', app.company),
            if (jobId != null && jobId.isNotEmpty)
              FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                future: FirebaseFirestore.instance
                    .collection('jobs')
                    .doc(jobId)
                    .get(),
                builder: (context, snap) {
                  final poster =
                      (snap.data?.data()?['poster_name'] ?? '').toString();
                  if (poster.isEmpty) return const SizedBox.shrink();
                  return _contactRow(
                      Icons.person_outline, 'Narahubung (HR)', poster);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _contactRow(IconData icon, String label, String value) => Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: Colors.green),
            const SizedBox(width: 8),
            Expanded(
              child: Text.rich(TextSpan(children: [
                TextSpan(
                    text: '$label: ',
                    style: const TextStyle(color: Colors.grey)),
                TextSpan(
                    text: value,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
              ])),
            ),
          ],
        ),
      );

  /// The company's accept/reject message to the applicant, when present.
  Widget _decisionNoteCard(BuildContext context, Application app) {
    final accepted = app.status == 'Tawaran Diterima';
    return Card(
      color: accepted ? Colors.green.shade50 : Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Pesan dari perusahaan',
                style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 4),
            Text(app.decisionNote ?? ''),
          ],
        ),
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
