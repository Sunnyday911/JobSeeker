import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:jobseeker/features/jobs/add_jobs_screen.dart';
import 'package:jobseeker/features/jobs/jobs_screen.dart';

/// A company's own postings (Change Plan 2.0, Part 4): `jobs where createdBy ==
/// uid`. Reuses [CompanyJobsView]'s card layout via its optional query param.
/// Standalone-pushable so it can serve as the `my_jobs` notification route.
class MyJobsScreen extends StatelessWidget {
  const MyJobsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final query = FirebaseFirestore.instance
        .collection('jobs')
        .where('createdBy', isEqualTo: uid);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lowongan Saya'),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddJobScreen()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Pasang Lowongan'),
      ),
      body: uid == null
          ? const Center(child: Text('Anda belum masuk.'))
          : CompanyJobsView(
              isCompany: true,
              query: query,
              emptyMessage: 'Anda belum memasang lowongan.',
            ),
    );
  }
}
