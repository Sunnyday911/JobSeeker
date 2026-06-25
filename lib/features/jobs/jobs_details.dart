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
              Navigator.pop(dialogContext); // Tutup dialog
              _deleteJob(context);          // Jalankan fungsi hapus
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
    // Ekstrak data
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
      // MENGGUNAKAN LISTVIEW AGAR STRUKTURNYA SAMA DENGAN ADD FORM
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // 1. HEADER (Ikon, Judul, Perusahaan)
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade100),
                ),
                child: const Icon(Icons.work,
                    color: Colors.blueAccent, size: 40),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      company,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.blueAccent.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),
          const Divider(height: 1, thickness: 1),
          const SizedBox(height: 24),

          // 2. INFORMASI META (Lokasi, Kategori, Gaji, Poster)
          // Menggunakan struktur baris yang konsisten
          if (location != null && location.toString().isNotEmpty)
            _metaItem(Icons.location_on_outlined, 'Lokasi', location.toString()),

          if (category != null && category.toString().isNotEmpty)
            _metaItem(Icons.category_outlined, 'Kategori', category.toString()),

          if (salary != null && salary.toString().isNotEmpty)
            _metaItem(Icons.payments_outlined, 'Gaji', salary.toString()),

          _metaItem(Icons.person_outline, 'Diposting oleh', posterName),

          const SizedBox(height: 24),

          // 3. DESKRIPSI (Dibuat dalam kotak bergaris menyerupai TextField form)
          const Text(
            'Deskripsi Pekerjaan',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              border: Border.all(color: Colors.grey.shade400),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              description,
              style: const TextStyle(
                  fontSize: 15, height: 1.6, color: Colors.black87),
            ),
          ),

          const SizedBox(height: 32),

          // 4. TOMBOL AKSI BAWAH
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

          const SizedBox(height: 16), // Ruang ekstra di bawah tombol
        ],
      ),
    );
  }

  // Widget bantuan untuk menampilkan baris informasi meta secara rapi
  Widget _metaItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: Colors.blueAccent),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.black87),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}