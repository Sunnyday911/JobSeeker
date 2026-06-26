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

  /// All applicants to jobs owned by the current company, newest first
  /// (Change Plan 2.0, Part 3). Sorted client-side to avoid a composite index;
  /// per-job filtering is done client-side by the applicants screen.
  Stream<List<Application>> watchApplicantsForMyJobs() => _col
          .where('jobOwnerId', isEqualTo: _uid)
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
    // Notify the owning company of a new applicant (Part 8). Best-effort:
    // never block the apply on a notification failure. Adzuna applies have
    // no owner → no notification.
    final ownerId = app.jobOwnerId;
    if (ownerId != null && ownerId.isNotEmpty) {
      try {
        await _notify(
          ownerId,
          title: 'Pelamar baru',
          body: '${app.fullName} melamar ${app.jobTitle}',
          route: 'my_jobs',
        );
      } catch (_) {/* ignore notification failure */}
    }
  }

  /// Writes an in-app notification doc to another user's subcollection, using
  /// the same shape the notification center already consumes (forum/reminders).
  Future<void> _notify(
    String uid, {
    required String title,
    required String body,
    String? route,
  }) =>
      _db.collection('users').doc(uid).collection('notifications').add({
        'title': title,
        'body': body,
        'createdAt': Timestamp.now(),
        'read': false,
        'route': route,
      });

  /// Re-adds a deleted application (undo, US14.4).
  Future<void> restore(Application app) => _col.add(app.toMap());

  /// Edits the applicant form fields (US13 / Update).
  Future<void> updateForm(
    String id, {
    required String fullName,
    required String dateOfBirth,
    required String address,
    required String phone,
    required String platform,
    required String notes,
  }) =>
      _col.doc(id).update({
        'fullName': fullName,
        'dateOfBirth': dateOfBirth,
        'address': address,
        'phone': phone,
        'platform': platform,
        'notes': notes,
        'updatedAt': Timestamp.now(),
      });

  /// Updates status + appends to history (US13.2/13.3/13.4).
  /// Called by the SEEKER on their own application — no notification (the actor
  /// is the owner of the doc).
  Future<void> updateStatus(String id, String status) => _col.doc(id).update({
        'status': status,
        'updatedAt': Timestamp.now(),
        'statusHistory': FieldValue.arrayUnion([
          {'status': status, 'at': Timestamp.now()},
        ]),
      });

  /// Company-side status change (Change Plan 2.0, Parts 3/8/9): performs the same
  /// status update AND notifies the seeker. Used for moving the pipeline, for
  /// "accepting" ('Tawaran Diterima') and "rejecting" ('Ditolak') — the company
  /// never hard-deletes the shared application doc. The optional [note] is the
  /// company's message/reason, stored on the application and shown to the seeker.
  Future<void> updateStatusByCompany(
    Application app,
    String status, {
    String? note,
  }) async {
    final trimmedNote = note?.trim();
    final hasNote = trimmedNote != null && trimmedNote.isNotEmpty;
    await _col.doc(app.id).update({
      'status': status,
      'updatedAt': Timestamp.now(),
      'statusHistory': FieldValue.arrayUnion([
        {'status': status, 'at': Timestamp.now()},
      ]),
      if (hasNote) 'decisionNote': trimmedNote,
    });
    if (app.userId.isNotEmpty) {
      // Tailor the message by decision; fall back to the generic update text.
      String title;
      String body;
      if (status == 'Tawaran Diterima') {
        title = 'Selamat! Lamaran diterima 🎉';
        body = '${app.jobTitle} di ${app.company} menerima lamaran Anda.';
      } else if (status == 'Ditolak') {
        title = 'Hasil lamaran';
        body = 'Mohon maaf, lamaran ${app.jobTitle} belum berhasil.';
      } else {
        title = 'Status lamaran diperbarui';
        body = '${app.jobTitle}: $status';
      }
      if (hasNote) body = '$body\n$trimmedNote';
      try {
        await _notify(
          app.userId,
          title: title,
          body: body,
          route: 'my_applications',
        );
      } catch (_) {/* best-effort, must not block the status update */}
    }
  }

  Future<void> deleteApplication(String id) => _col.doc(id).delete();

  /// Client-side 7-day reminder (US13.5): for each active application not
  /// updated in >7 days, create an in-app notification once per stale window.
  /// Runs without Cloud Functions (Spark) — call it when the tracker opens.
  Future<void> remindStaleApplications() async {
    final snap = await _col.where('userId', isEqualTo: _uid).get();
    final now = DateTime.now();
    final cutoff = now.subtract(const Duration(days: 7));
    final notifCol =
        _db.collection('users').doc(_uid).collection('notifications');

    for (final doc in snap.docs) {
      final app = Application.fromFirestore(doc);
      final isActive =
          app.status != 'Ditolak' && app.status != 'Tawaran Diterima';
      final lastUpdate = app.updatedAt ?? app.appliedAt;
      if (!isActive || lastUpdate == null || lastUpdate.isAfter(cutoff)) {
        continue;
      }
      // Skip if we already reminded since the last update (avoid duplicates).
      if (app.reminderSentAt != null &&
          app.reminderSentAt!.isAfter(lastUpdate)) {
        continue;
      }
      await notifCol.add({
        'title': 'Pengingat lamaran',
        'body':
            'Lamaran "${app.jobTitle}" di ${app.company} belum diperbarui lebih dari 7 hari.',
        'createdAt': Timestamp.now(),
        'read': false,
        'route': null,
      });
      await doc.reference.update({'reminderSentAt': Timestamp.fromDate(now)});
    }
  }
}
