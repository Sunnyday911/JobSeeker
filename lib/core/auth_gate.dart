import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:jobseeker/features/home/main_screen.dart';
import 'package:jobseeker/features/models/app_user.dart';
import 'package:jobseeker/features/onboarding/onboarding_screen.dart';
import 'package:jobseeker/features/repositories/user_repository.dart';
import 'package:jobseeker/features/screens/login.dart';

/// Root widget that decides where an authenticated session lands:
/// - signed out                  -> LoginScreen
/// - signed in, not onboarded     -> OnboardingScreen (US03.1)
/// - signed in, onboarded         -> MainScreen (US01.4)
///
/// Because it watches the profile stream, completing onboarding flips the user
/// to the dashboard automatically without manual navigation.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnap) {
        if (authSnap.connectionState == ConnectionState.waiting) {
          return const _Loading();
        }
        if (!authSnap.hasData) {
          return const LoginScreen();
        }

        return StreamBuilder<AppUser?>(
          stream: UserRepository().watchCurrentProfile(),
          builder: (context, profileSnap) {
            if (profileSnap.connectionState == ConnectionState.waiting) {
              return const _Loading();
            }
            final profile = profileSnap.data;
            // Profile briefly missing right after sign-in: show a spinner.
            if (profile == null) return const _Loading();
            if (!profile.onboardingCompleted) {
              return const OnboardingScreen();
            }
            return const MainScreen();
          },
        );
      },
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
