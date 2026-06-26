import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String uid;
  final String email;
  final String role;
  final String? fullName;
  final String? phoneNumber;
  final String? bio;
  final String? industry;
  final String? experienceLevel;
  final String? city;
  final bool onboardingCompleted;
  // Company-specific onboarding flag (separate from the seeker `onboardingCompleted`)
  // so existing companies are routed through the company form exactly once.
  final bool companyOnboarded;

  AppUser({
    required this.uid,
    required this.email,
    required this.role,
    required this.onboardingCompleted,
    this.fullName,
    this.phoneNumber,
    this.bio,
    this.industry,
    this.experienceLevel,
    this.city,
    this.companyOnboarded = false,
  });

  bool get isAdmin => role == 'admin';
  bool get isCompany => role == 'company';
  bool get isSeeker => role == 'seeker';

  factory AppUser.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc,
      ) {
    final data = doc.data() ?? {};

    return AppUser(
    uid: doc.id,
    email: data['email'] ?? '',
    role: data['role'] ?? 'seeker',
    fullName: data['fullName'],
    phoneNumber: data['phoneNumber'],
    bio: data['bio'],
    industry: data['industry'],
    experienceLevel: data['experienceLevel'],
    city: data['city'],
    onboardingCompleted:
    data['onboardingCompleted'] ?? false,
    companyOnboarded: data['companyOnboarded'] ?? false,
    );

  }
}
