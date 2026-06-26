import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:jobseeker/core/constants.dart';
import 'package:jobseeker/features/models/application.dart';
import 'package:jobseeker/features/repositories/application_repository.dart';

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

  // Perbaikan 1: Gunakan StatefulBuilder untuk manajemen controller yang aman di dialog
  Future<String?> _askDecision(
      BuildContext context, {
        required String title,
        required String message,
        required String confirmLabel,
        required Color confirmColor,
      }) async {
    String note = '';
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return _DecisionDialog(
          title: title,
          message: message,
          confirmLabel: confirmLabel,
          confirmColor: confirmColor,
          onNoteChanged: (v) => note = v,
        );
      },
    );
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
    // Perbaikan 2: Tangkap ScaffoldMessengerState sebelum proses async
    final messenger = ScaffoldMessenger.of(context);

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

      // Gunakan messenger yang sudah ditangkap agar aman dari unmounting
      messenger.showSnackBar(SnackBar(content: Text(successMessage)));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Gagal: $e')));
    }
  }

  // ... (Metode _accept, _reject, _changeStatus tetap sama)
  Future<void> _accept(BuildContext context) => _decide(
    context,
    status: 'Tawaran Diterima',
    title: 'Terima Pelamar',
    message: 'Terima lamaran ${app.fullName}?',
    confirmLabel: 'Terima',
    confirmColor: Colors.green,
    successMessage: 'Pelamar diterima.',
  );

  Future<void> _reject(BuildContext context) => _decide(
    context,
    status: 'Ditolak',
    title: 'Tolak Pelamar',
    message: 'Tolak lamaran ${app.fullName}?',
    confirmLabel: 'Tolak',
    confirmColor: Colors.red,
    successMessage: 'Pelamar ditolak.',
  );

  Future<void> _changeStatus(BuildContext context, String status) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await repo.updateStatusByCompany(app, status);
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Gagal: $e')));
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
            Text(app.fullName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: kApplicationStatuses.contains(app.status) ? app.status : null,
                    items: kApplicationStatuses.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                    onChanged: (v) => v != null ? _changeStatus(context, v) : null,
                  ),
                ),
                IconButton.filled(
                  onPressed: () => _accept(context),
                  icon: const Icon(Icons.check),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: () => _reject(context),
                  icon: const Icon(Icons.close),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Perbaikan 3: Pisahkan Dialog menjadi StatefulWidget agar controller aman
class _DecisionDialog extends StatefulWidget {
  final String title;
  final String message;
  final String confirmLabel;
  final Color confirmColor;
  final ValueChanged<String> onNoteChanged;

  const _DecisionDialog({
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.confirmColor,
    required this.onNoteChanged,
  });

  @override
  State<_DecisionDialog> createState() => _DecisionDialogState();
}

class _DecisionDialogState extends State<_DecisionDialog> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(widget.message),
          const SizedBox(height: 12),
          TextField(
            controller: _ctrl,
            maxLines: 3,
            onChanged: widget.onNoteChanged,
            decoration: const InputDecoration(
              labelText: 'Pesan (opsional)',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(widget.confirmLabel, style: TextStyle(color: widget.confirmColor)),
        ),
      ],
    );
  }
}