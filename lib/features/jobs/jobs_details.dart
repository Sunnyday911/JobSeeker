import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jobseeker/features/jobs/jobs_edit.dart'; // Sesuaikan path foldernya jika berbeda

class JobDetailScreen extends StatelessWidget {
  final String jobId;
  final Map<String, dynamic> jobData;
  final String userRole;

  const JobDetailScreen({
    super.key,
    required this.jobId,
    required this.jobData,
    required this.userRole,
  });

  // Fungsi untuk menghapus data dari Firestore
  void _deleteJob(BuildContext context) async {
    try {
      await FirebaseFirestore.instance.collection('jobs').doc(jobId).delete();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lowongan berhasil dihapus!')),
        );
        // Kembali ke halaman JobsScreen setelah berhasil menghapus
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

  // Fungsi untuk menampilkan dialog konfirmasi hapus
  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Hapus Lowongan'),
          content: const Text('Apakah Anda yakin ingin menghapus lowongan ini? Tindakan ini tidak dapat dibatalkan.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext), // Tutup dialog jika batal
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext); // Tutup dialog terlebih dahulu
                _deleteJob(context); // Jalankan fungsi hapus
              },
              child: const Text('Hapus', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = jobData['title'] ?? 'Posisi Tidak Diketahui';
    final company = jobData['company'] ?? 'Perusahaan Tidak Diketahui';
    final posterName = jobData['poster_name'] ?? 'Anonim';
    final description = jobData['description'] ?? 'Tidak ada deskripsi pekerjaan untuk lowongan ini.';

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
            // Bagian Atas: Ikon Besar + Judul
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.work, color: Colors.blueAccent, size: 40),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        company,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.blueAccent.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 40, thickness: 1),

            // Bagian Tengah: Info Pembuat Lowongan
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.person, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    'Diposting oleh: $posterName',
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Bagian Bawah: Deskripsi Pekerjaan
            const Text(
              'Deskripsi Pekerjaan',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: const TextStyle(fontSize: 15, height: 1.6, color: Colors.black87),
            ),
            const SizedBox(height: 40),

            // LOGIKA TOMBOL BERDASARKAN ROLE
            userRole == 'HR'
                ? Row(
              children: [
                // TOMBOL EDIT INFO (Porsi lebih besar)
                Expanded(
                  flex: 3,
                  child: SizedBox(
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EditJobScreen(
                              jobId: jobId,
                              jobData: jobData,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.edit),
                      label: const Text('Edit Info', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // TOMBOL DELETE (Porsi lebih kecil, warna merah)
                Expanded(
                  flex: 1,
                  child: SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () => _showDeleteConfirmation(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: EdgeInsets.zero, // Biar ikon pas di tengah
                      ),
                      child: const Icon(Icons.delete_forever, size: 26),
                    ),
                  ),
                ),
              ],
            )
                : SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Berhasil melamar pekerjaan!')),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Apply Now', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}