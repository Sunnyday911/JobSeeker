import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:jobseeker/features/models/application.dart';

/// CRUD for job applications in the top-level `applications` collection,
/// scoped by `userId` (US12–US14). Lists are sorted client-side to avoid a
/// composite Firestore index.
class ApplicationRepository {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String get _uid => _auth.currentUser!.uid;
  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('applications');

  /// All of the current user's applications, newest first (US12.4).
  Stream<List<Application>> watchMyApplications() => _col
          .where('userId', isEqualTo: _uid)
          .snapshots()
          .map((snap) {
        final apps = snap.docs.map(Application.fromFirestore).toList();
        apps.sort((a, b) => (b.appliedAt ?? DateTime(0))
            .compareTo(a.appliedAt ?? DateTime(0)));
        return apps;
      });

  /// True if the user already has an application for [jobId] (US12.5).
  Future<bool> hasApplied(String jobId) async {
    final q = await _col.where('userId', isEqualTo: _uid).get();
    return q.docs.any((d) => (d.data()['jobId'] ?? '') == jobId);
  }

  Future<void> createApplication(Application app) async {
    final jid = app.jobId;
    if (jid != null && jid.isNotEmpty && await hasApplied(jid)) {
      throw Exception('Kamu sudah melamar lowongan ini.');
    }
    await _col.add(app.toMap());
  }

  /// Re-adds a deleted application (undo, US14.4).
  Future<void> restore(Application app) => _col.add(app.toMap());

  /// Edits the applicant form fields (US13 / Update).
  Future<void> updateForm(
    String id, {
    required String fullName,
    required String dateOfBirth,
    required String address,
    required String phone,
    required String notes,
  }) =>
      _col.doc(id).update({
        'fullName': fullName,
        'dateOfBirth': dateOfBirth,
        'address': address,
        'phone': phone,
        'notes': notes,
        'updatedAt': Timestamp.now(),
      });

  /// Updates status + appends to history (US13.2/13.3/13.4).
  Future<void> updateStatus(String id, String status) => _col.doc(id).update({
        'status': status,
        'updatedAt': Timestamp.now(),
        'statusHistory': FieldValue.arrayUnion([
          {'status': status, 'at': Timestamp.now()},
        ]),
      });

  Future<void> deleteApplication(String id) => _col.doc(id).delete();
}
