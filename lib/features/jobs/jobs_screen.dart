import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:jobseeker/features/jobs/add_jobs_screen.dart';
import 'package:jobseeker/features/jobs/jobs_details.dart'; // Sesuaikan path foldernya jika berbeda

class JobsScreen extends StatefulWidget {
  const JobsScreen({super.key});

  @override
  State<JobsScreen> createState() => _JobsScreenState();
}

class _JobsScreenState extends State<JobsScreen> {
  String _userRole = 'Applicant'; // Default role (buat jaga-jaga kalau bukan HR)
  bool _isLoadingRole = true;

  @override
  void initState() {
    super.initState();
    _fetchUserRole();
  }

  // Fungsi untuk mengecek role user (Versi Cek Email - Tahan Banting)
  Future<void> _fetchUserRole() async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        // Ambil email user yang sedang login
        final userEmail = user.email ?? '';

        setState(() {
          // Kalau email-nya dimulai dengan kata 'hr' (misal: hr@gmail.com)
          if (userEmail.toLowerCase().startsWith('hr')) {
            _userRole = 'HR';
          } else {
            _userRole = 'Applicant';
          }
        });
      }
    } catch (e) {
      debugPrint('Gagal mengambil role: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingRole = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Job Opportunities'),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),

      // LOGIKA TOMBOL ADD JOBS
      floatingActionButton: _isLoadingRole
          ? const CircularProgressIndicator()
          : _userRole == 'HR'
          ? FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context)=> const AddJobScreen()),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Job'),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      )
          : null, // Sembunyikan tombol jika bukan HR

      // BACA DATA REAL-TIME DARI FIRESTORE
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('jobs').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text('Terjadi kesalahan saat memuat data.'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Belum ada lowongan pekerjaan.'));
          }

          final jobs = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: jobs.length,
            itemBuilder: (context, index) {
              // AMBIL DOKUMEN DAN ID-NYA DI SINI
              final jobDoc = jobs[index];
              final String jobId = jobDoc.id; // <-- Ini ID yang dibutuhkan untuk Edit
              final jobData = jobDoc.data() as Map<String, dynamic>;

              final title = jobData['title'] ?? 'Posisi Tidak Diketahui';
              final company = jobData['company'] ?? 'Perusahaan Tidak Diketahui';
              final posterName = jobData['poster_name'] ?? 'Anonim';

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.work, color: Colors.blueAccent),
                  ),
                  title: Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 6.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          company,
                          style: const TextStyle(color: Colors.black87),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Diposting oleh: $posterName',
                          style: const TextStyle(
                              fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    // Pindah ke Detail Job dengan membawa jobId, jobData, DAN userRole
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => JobDetailScreen(
                              jobId: jobId,        // <-- Kirim ID dokumen
                              jobData: jobData,    // <-- Kirim isi data
                              userRole: _userRole, // <-- Kirim role user
                            )
                        )
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}