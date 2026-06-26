import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:jobseeker/core/constants.dart';
import 'package:jobseeker/features/models/application.dart';
import 'package:jobseeker/features/repositories/application_repository.dart';

/// Applicants to a single company-owned job (Change Plan 2.0, Part 3).
/// Streams all of the company's applicants and filters to this [jobId]
/// client-side (no composite index). The company can move an applicant's
/// status or "reject" them (status → 'Ditolak'); it never hard-deletes the
/// seeker's shared application doc.
class JobApplicantsScreen extends StatelessWidget {
  final String jobId;
  final String jobTitle;

  const JobApplicantsScreen({
    super.key,
    required this.jobId,
    required this.jobTitle,
  });

  @override
  Widget build(BuildContext context) {
    final repo = ApplicationRepository();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pelamar'),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<Application>>(
        stream: repo.watchApplicantsForMyJobs(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Gagal memuat pelamar: ${snap.error}'));
          }
          final applicants =
              (snap.data ?? []).where((a) => a.jobId == jobId).toList();
          if (applicants.isEmpty) {
            return const Center(child: Text('Belum ada pelamar'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: applicants.length,
            itemBuilder: (context, i) =>
                _ApplicantCard(repo: repo, app: applicants[i]),
            separatorBuilder: (context, index) => const SizedBox(height: 12),
          );
        },
      ),
    );
  }
}

class _ApplicantCard extends StatelessWidget {
  final ApplicationRepository repo;
  final Application app;

  const _ApplicantCard({required this.repo, required this.app});

  /// Shared accept/reject dialog with an optional note. Returns the trimmed note
  /// when confirmed (empty string = no note), or null when cancelled.
  Future<String?> _askDecision(
    BuildContext context, {
    required String title,
    required String message,
    required String confirmLabel,
    required Color confirmColor,
  }) async {
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Pesan untuk pelamar (opsional)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(confirmLabel,
                style: TextStyle(
                    color: confirmColor, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    final note = ctrl.text.trim();
    ctrl.dispose();
    return ok == true ? note : null;
  }

  Future<void> _decide(
    BuildContext context, {
    required String status,
    required String title,
    required String message,
    required String confirmLabel,
    required Color confirmColor,
    required String successMessage,
  }) async {
    final note = await _askDecision(
      context,
      title: title,
      message: message,
      confirmLabel: confirmLabel,
      confirmColor: confirmColor,
    );
    if (note == null) return;
    try {
      await repo.updateStatusByCompany(app, status,
          note: note.isEmpty ? null : note);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(successMessage)),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal: $e')),
        );
      }
    }
  }

  Future<void> _accept(BuildContext context) => _decide(
        context,
        status: 'Tawaran Diterima',
        title: 'Terima Pelamar',
        message:
            'Terima lamaran ${app.fullName}? Pelamar akan diberi tahu dan status menjadi "Tawaran Diterima".',
        confirmLabel: 'Terima',
        confirmColor: Colors.green,
        successMessage: 'Pelamar diterima.',
      );

  Future<void> _reject(BuildContext context) => _decide(
        context,
        status: 'Ditolak',
        title: 'Tolak Pelamar',
        message:
            'Tolak lamaran ${app.fullName}? Statusnya menjadi "Ditolak" dan pelamar diberi tahu.',
        confirmLabel: 'Tolak',
        confirmColor: Colors.red,
        successMessage: 'Pelamar ditolak.',
      );

  Future<void> _changeStatus(BuildContext context, String status) async {
    try {
      await repo.updateStatusByCompany(app, status);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memperbarui status: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final applied = app.appliedAt != null
        ? DateFormat('d MMM yyyy').format(app.appliedAt!)
        : '-';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(app.fullName,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            if (app.phone.isNotEmpty)
              _line(Icons.phone_outlined, app.phone),
            if (app.platform.isNotEmpty)
              _line(Icons.send_outlined, app.platform),
            _line(Icons.event_outlined, 'Melamar $applied'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: kApplicationStatuses.contains(app.status)
                        ? app.status
                        : null,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Status',
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: kApplicationStatuses
                        .map((s) =>
                            DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: (v) {
                      if (v != null && v != app.status) {
                        _changeStatus(context, v);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                IconButton.filled(
                  onPressed: () => _accept(context),
                  tooltip: 'Terima pelamar',
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.how_to_reg_outlined),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: () => _reject(context),
                  tooltip: 'Tolak pelamar',
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.person_off_outlined),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _line(IconData icon, String text) => Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Row(
          children: [
            Icon(icon, size: 16, color: Colors.grey),
            const SizedBox(width: 8),
            Expanded(child: Text(text)),
          ],
        ),
      );
}
