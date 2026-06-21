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
          return const Center(
              child: Text('Terjadi kesalahan saat memuat data.'));
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
            final title = jobData['title'] ?? 'Posisi Tidak Diketahui';
            final company = jobData['company'] ?? 'Perusahaan Tidak Diketahui';
            final posterName = jobData['poster_name'] ?? 'Anonim';

            return Card(
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: Colors.blue.shade50, shape: BoxShape.circle),
                  child: const Icon(Icons.work, color: Colors.blueAccent),
                ),
                title: Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 6.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(company,
                          style: const TextStyle(color: Colors.black87)),
                      const SizedBox(height: 4),
                      Text('Diposting oleh: $posterName',
                          style: const TextStyle(
                              fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
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
              ),
            );
          },
        );
      },
    );
  }
}
