import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jobseeker/features/jobs/jobs_details.dart';

/// Embeddable list of internal company-posted jobs (the `jobs` collection),
/// hosted by the "Perusahaan" segment of the Lowongan tab (#3). No Scaffold —
/// the posting FAB lives on the parent. [isCompany] toggles owner actions in
/// the detail screen.
class CompanyJobsView extends StatelessWidget {
  final bool isCompany;
  const CompanyJobsView({super.key, required this.isCompany});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('jobs').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(child: Text('Terjadi kesalahan saat memuat data.'));
        }
        final jobs = snapshot.data?.docs ?? [];
        if (jobs.isEmpty) {
          return const Center(child: Text('Belum ada lowongan perusahaan.'));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: jobs.length,
          itemBuilder: (context, index) {
            final jobDoc = jobs[index];
            final jobId = jobDoc.id;
            final jobData = jobDoc.data() as Map<String, dynamic>;

            // Ekstrak data (dengan fallback value jika field belum ada di Firestore)
            final title = jobData['title'] ?? 'Posisi Tidak Diketahui';
            final company = jobData['company'] ?? 'Perusahaan Tidak Diketahui';
            final category = jobData['category']; // Bisa null
            final location = jobData['location'] ?? 'Lokasi tidak ditentukan';
            final salary = jobData['salary'] ?? 'Gaji dirahasiakan';

            return Card(
              elevation: 0, // Mengubah elevasi agar rata seperti screenshot
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.shade300), // Garis luar tipis
              ),
              color: Colors.grey.shade50, // Latar belakang sedikit abu-abu
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CompanyJobDetailScreen(
                      jobId: jobId,
                      jobData: jobData,
                      isCompany: isCompany,
                    ),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Baris 1: Judul Pekerjaan & Tag Kategori
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          // Menampilkan pill kategori hanya jika datanya ada
                          if (category != null && category.toString().isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade100, // Warna biru muda
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                category,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.blue.shade800,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),

                      // Baris 2: Nama Perusahaan
                      Text(
                        company,
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Baris 3: Ikon Pin + Lokasi
                      Row(
                        children: [
                          Icon(Icons.location_on_outlined,
                              size: 16, color: Colors.grey.shade500),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              location,
                              style: TextStyle(
                                  fontSize: 13, color: Colors.grey.shade600),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),

                      // Baris 4: Ikon Uang + Gaji
                      Row(
                        children: [
                          Icon(Icons.payments_outlined,
                              size: 16, color: Colors.grey.shade500),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              salary,
                              style: TextStyle(
                                  fontSize: 13, color: Colors.grey.shade600),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}