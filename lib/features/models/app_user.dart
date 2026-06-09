import 'package:cloud_firestore/cloud_firestore.dart';

/// Profile document stored at `users/{uid}`.
class AppUser {
  final String uid;
  final String email;
  final String role; // 'user' | 'admin'
  final String? industry;
  final String? experienceLevel;
  final bool onboardingCompleted;

  AppUser({
    required this.uid,
    required this.email,
    required this.role,
    required this.industry,
    required this.experienceLevel,
    required this.onboardingCompleted,
  });

  bool get isAdmin => role == 'admin';

  factory AppUser.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return AppUser(
      uid: doc.id,
      email: data['email'] ?? '',
      role: data['role'] ?? 'user',
      industry: data['industry'],
      experienceLevel: data['experienceLevel'],
      onboardingCompleted: data['onboardingCompleted'] ?? false,
    );
  }
}
