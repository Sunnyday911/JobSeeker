import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:jobseeker/features/models/job.dart';

/// Saved/favorite jobs under `users/{uid}/savedJobs/{jobId}` (US07).
class SavedJobRepository {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _col => _db
      .collection('users')
      .doc(_auth.currentUser!.uid)
      .collection('savedJobs');

  /// Live saved-state for a job, drives the bookmark icon (US07.2).
  Stream<bool> watchIsSaved(String jobId) =>
      _col.doc(jobId).snapshots().map((snap) => snap.exists);

  /// Adds or removes a saved job (US07.1/07.5).
  Future<void> toggle(Job job) async {
    final ref = _col.doc(job.id);
    final snap = await ref.get();
    if (snap.exists) {
      await ref.delete();
    } else {
      await ref.set({
        ...job.toMap(),
        'savedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> remove(String jobId) => _col.doc(jobId).delete();

  /// Updates the user's personal note on a saved job (US07 — UPDATE).
  Future<void> updateNote(String jobId, String note) => _col.doc(jobId).update({
        'note': note,
        'updatedAt': FieldValue.serverTimestamp(),
      });

  /// All saved jobs, newest-saved first (US07.4).
  Stream<List<Job>> watchSavedJobs() => _col
      .orderBy('savedAt', descending: true)
      .snapshots()
      .map((snap) => snap.docs.map((d) => Job.fromMap(d.data())).toList());
}
