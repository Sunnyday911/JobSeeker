import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:jobseeker/features/models/cv_profile.dart';
import 'package:jobseeker/features/models/job_recommendation.dart';

/// Persists the extracted CV profile (US08.6) and AI recommendations (US09.7).
/// Only the extracted profile is stored — never the raw CV text.
class CvRepository {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String get _uid => _auth.currentUser!.uid;

  DocumentReference<Map<String, dynamic>> get _profileDoc =>
      _db.collection('cvProfiles').doc(_uid);

  Future<void> saveProfile(CvProfile profile) => _profileDoc.set({
        ...profile.toJson(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

  Future<CvProfile?> getProfile() async {
    final snap = await _profileDoc.get();
    if (!snap.exists) return null;
    return CvProfile.fromJson(snap.data()!);
  }

  Stream<CvProfile?> watchProfile() => _profileDoc
      .snapshots()
      .map((s) => s.exists ? CvProfile.fromJson(s.data()!) : null);

  Future<void> saveRecommendations(List<JobRecommendation> recs) =>
      _db.collection('recommendations').doc(_uid).set({
        'items': recs.map((r) => r.toJson()).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

  /// Reads the saved recommendations (US09.7) for the dashboard (US15.3).
  Future<List<JobRecommendation>> getRecommendations() async {
    final snap = await _db.collection('recommendations').doc(_uid).get();
    if (!snap.exists) return [];
    final items = snap.data()?['items'] as List<dynamic>? ?? [];
    return items
        .map((e) => JobRecommendation.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Deletes the CV profile and its derived recommendations (US08 — DELETE).
  Future<void> deleteProfile() async {
    await _profileDoc.delete();
    await _db.collection('recommendations').doc(_uid).delete();
  }
}
