// Centralized third-party API credentials.
//
// ⚠️ SECURITY: keys hardcoded in a Flutter app are extractable from the built
// APK/IPA. This is acceptable for a course project. For production, move these
// behind a backend/Cloud Function proxy and inject at build time with
// `--dart-define` instead of committing them. Rotate the Anthropic key after
// the course — it was shared in plaintext.
class ApiKeys {
  ApiKeys._();

  // Adzuna (jobs) — https://developer.adzuna.com
  static const String adzunaAppId = '';
  static const String adzunaAppKey = '';

  // Anthropic / Claude (CV analysis + recommendations)
  static const String anthropic =
     '' ;
}
