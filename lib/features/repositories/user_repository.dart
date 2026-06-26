import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:jobseeker/features/models/app_user.dart';

/// Reads and writes the `users/{uid}` profile document.
class UserRepository {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  DocumentReference<Map<String, dynamic>> _doc(String uid) =>
      _db.collection('users').doc(uid);

  /// Creates the initial profile on registration (US01). New users start as
  /// 'user' with onboarding pending.
  Future<void> createProfile(String uid, String email, {required String fullName, required String role,}
      ) async {
    await _doc(uid).set({
      'email': email,
      'role': role,
      'fullName': fullName,
      'phoneNumber': '',
      'bio': '',
      'industry': null,
      'experienceLevel': null,
      'city': null,
      'onboardingCompleted': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// One-shot read of the current user's profile, or null if missing.
  Future<AppUser?> getCurrentProfile() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;
    final snap = await _doc(uid).get();
    if (!snap.exists) return null;
    return AppUser.fromFirestore(snap);
  }

  /// Live stream of the current user's profile.
  Stream<AppUser?> watchCurrentProfile() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return Stream.value(null);
    return _doc(uid).snapshots().map(
          (snap) => snap.exists ? AppUser.fromFirestore(snap) : null,
    );
  }

  /// Saves onboarding choices and marks onboarding complete (US03.4).
  Future<void> completeOnboarding({
    required String industry,
    required String city,
    required String experienceLevel,
  }) async {
    final uid = _auth.currentUser!.uid;
    await _doc(uid).update({
      'industry': industry,
      'city': city,
      'experienceLevel': experienceLevel,
      'onboardingCompleted': true,
    });
  }

  /// Saves the minimal company onboarding and marks the company onboarded.
  /// Also sets `onboardingCompleted: true` so any code reading that flag stays
  /// valid for companies.
  Future<void> completeCompanyOnboarding({
    required String companyName,
    required String city,
    required String industry,
  }) async {
    final uid = _auth.currentUser!.uid;
    await _doc(uid).update({
      'fullName': companyName,
      'city': city,
      'industry': industry,
      'companyOnboarded': true,
      'onboardingCompleted': true,
    });
  }

  Future updateProfile({
    required String fullName,
    required String phoneNumber,
    required String bio,
    String? city,
    String? industry,
  }) async {
    final uid = _auth.currentUser!.uid;

    await _doc(uid).update({
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'bio': bio,
      // Optional company fields — only written when provided, so the seeker
      // call path (fullName/phoneNumber/bio) is unchanged.
      if (city != null) 'city': city,
      if (industry != null) 'industry': industry,
    });
  }

  Future deleteProfile() async {
    final uid = _auth.currentUser!.uid;
    await _doc(uid).delete();
    await _auth.currentUser?.delete();
  }
}

