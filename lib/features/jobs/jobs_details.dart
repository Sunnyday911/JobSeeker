import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jobseeker/features/jobs/jobs_edit.dart';
import 'package:jobseeker/features/models/job.dart';
import 'package:jobseeker/features/applications/apply_form_screen.dart';

/// Detail for an internal company-posted job (#3). Company owners get Edit /
/// Delete; applicants get "Catat Lamaran" which records into the application
/// tracker (Cluster E).
class CompanyJobDetailScreen extends StatelessWidget {
  final String jobId;
  final Map<String, dynamic> jobData;
  final bool isCompany;

  const CompanyJobDetailScreen({
    super.key,
    required this.jobId,
    required this.jobData,
    required this.isCompany,
  });

  void _deleteJob(BuildContext context) async {
    try {
      await FirebaseFirestore.instance.collection('jobs').doc(jobId).delete();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lowongan berhasil dihapus!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menghapus lowongan: $e')),
        );
      }
    }
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus Lowongan'),
        content: const Text(
            'Apakah Anda yakin ingin menghapus lowongan ini? Tindakan ini tidak dapat dibatalkan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _deleteJob(context);
            },
            child: const Text('Hapus',
                style:
                    TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = jobData['title'] ?? 'Posisi Tidak Diketahui';
    final company = jobData['company'] ?? 'Perusahaan Tidak Diketahui';
    final posterName = jobData['poster_name'] ?? 'Anonim';
    final location = jobData['location'];
    final category = jobData['category'];
    final salary = jobData['salary'];
    final description = jobData['description'] ??
        'Tidak ada deskripsi pekerjaan untuk lowongan ini.';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Lowongan'),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.work,
                      color: Colors.blueAccent, size: 40),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: const TextStyle(
                              fontSize: 22, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(company,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.blueAccent.shade700,
                            fontWeight: FontWeight.w500,
                          )),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 40, thickness: 1),
            if (location != null && location.toString().isNotEmpty)
              _metaRow(Icons.location_on_outlined, location.toString()),
            if (category != null && category.toString().isNotEmpty)
              _metaRow(Icons.category_outlined, category.toString()),
            if (salary != null && salary.toString().isNotEmpty)
              _metaRow(Icons.payments_outlined, salary.toString()),
            _metaRow(Icons.person_outline, 'Diposting oleh: $posterName'),
            const SizedBox(height: 16),
            const Text('Deskripsi Pekerjaan',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(description,
                style: const TextStyle(
                    fontSize: 15, height: 1.6, color: Colors.black87)),
            const SizedBox(height: 40),
            if (isCompany)
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: SizedBox(
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                EditJobScreen(jobId: jobId, jobData: jobData),
                          ),
                        ),
                        icon: const Icon(Icons.edit),
                        label: const Text('Edit Info',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 1,
                    child: SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () => _showDeleteConfirmation(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                          padding: EdgeInsets.zero,
                        ),
                        child: const Icon(Icons.delete_forever, size: 26),
                      ),
                    ),
                  ),
                ],
              )
            else
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ApplyFormScreen(
                          job: Job.fromCompanyMap(jobId, jobData)),
                    ),
                  ),
                  icon: const Icon(Icons.assignment_outlined),
                  label: const Text('Catat Lamaran',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _metaRow(IconData icon, String text) => Padding(
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
