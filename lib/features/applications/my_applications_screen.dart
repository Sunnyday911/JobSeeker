import 'package:flutter/material.dart';
import 'package:jobseeker/core/constants.dart';
import 'package:jobseeker/features/models/application.dart';
import 'package:jobseeker/features/repositories/application_repository.dart';
import 'package:jobseeker/features/applications/application_detail_screen.dart';

/// "Lamaran Saya" — list of applications with stats, status filter, and
/// swipe-to-delete + undo (US12.4/12.6, US13.6, US14).
class MyApplicationsScreen extends StatefulWidget {
  const MyApplicationsScreen({super.key});

  @override
  State<MyApplicationsScreen> createState() => _MyApplicationsScreenState();
}

class _MyApplicationsScreenState extends State<MyApplicationsScreen> {
  final _repo = ApplicationRepository();
  String? _filter; // null = all

  @override
  void initState() {
    super.initState();
    // US13.5 — create in-app reminders for applications stale >7 days.
    _repo.remindStaleApplications();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lamaran Saya')),
      body: StreamBuilder<List<Application>>(
        stream: _repo.watchMyApplications(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final all = snap.data ?? [];
          if (all.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('Belum ada lamaran. Lamar dari halaman lowongan.'),
              ),
            );
          }
          final shown =
              _filter == null ? all : all.where((a) => a.status == _filter).toList();
          return Column(
            children: [
              _stats(all),
              _filters(),
              Expanded(child: _list(context, shown)),
            ],
          );
        },
      ),
    );
  }

  Widget _stats(List<Application> all) {
    final total = all.length;
    final interview = all.where((a) => a.status == 'Interview').length;
    final accepted = all.where((a) => a.status == 'Tawaran Diterima').length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          _statCard('Total', total),
          const SizedBox(width: 8),
          _statCard('Interview', interview),
          const SizedBox(width: 8),
          _statCard('Diterima', accepted),
        ],
      ),
    );
  }

  Widget _statCard(String label, int value) => Expanded(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              children: [
                Text('$value',
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold)),
                Text(label, style: const TextStyle(fontSize: 12)),
              ],
            ),
          ),
        ),
      );

  Widget _filters() => SizedBox(
        height: 44,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: ChoiceChip(
                label: const Text('Semua'),
                selected: _filter == null,
                onSelected: (_) => setState(() => _filter = null),
              ),
            ),
            ...kApplicationStatuses.map((s) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: Text(s),
                    selected: _filter == s,
                    onSelected: (_) => setState(() => _filter = s),
                  ),
                )),
          ],
        ),
      );

  Widget _list(BuildContext context, List<Application> apps) {
    if (apps.isEmpty) {
      return const Center(child: Text('Tidak ada lamaran untuk filter ini.'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: apps.length,
      itemBuilder: (context, i) {
        final app = apps[i];
        return Dismissible(
          key: Key(app.id),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            color: Theme.of(context).colorScheme.errorContainer,
            child: const Icon(Icons.delete_outline),
          ),
          confirmDismiss: (_) async {
            return await showDialog<bool>(
                  context: context,
                  builder: (d) => AlertDialog(
                    title: const Text('Hapus Lamaran'),
                    content: const Text('Yakin ingin menghapus lamaran ini?'),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(d, false),
                          child: const Text('Batal')),
                      TextButton(
                          onPressed: () => Navigator.pop(d, true),
                          child: const Text('Hapus',
                              style: TextStyle(color: Colors.red))),
                    ],
                  ),
                ) ??
                false;
          },
          onDismissed: (_) async {
            await _repo.deleteApplication(app.id);
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Lamaran dihapus'),
                action: SnackBarAction(
                  label: 'Batalkan',
                  onPressed: () => _repo.restore(app),
                ),
              ),
            );
          },
          child: Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              title: Text(app.jobTitle,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(app.company),
              trailing: Chip(
                label: Text(app.status, style: const TextStyle(fontSize: 11)),
                visualDensity: VisualDensity.compact,
              ),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      ApplicationDetailScreen(applicationId: app.id),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
