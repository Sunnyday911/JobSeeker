// Shared validators and FirebaseAuth error-code mapping for the auth screens
// (US01.2 validation, US01.5 friendly error messages).

/// Validates email format (US01.2). Returns null when valid.
String? validateEmail(String? value) {
  final v = value?.trim() ?? '';
  if (v.isEmpty) return 'Email tidak boleh kosong';
  final regex = RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$');
  if (!regex.hasMatch(v)) return 'Format email tidak valid';
  return null;
}

/// Validates password strength: minimum 8 characters (US01.2). Returns null
/// when valid.
String? validatePassword(String? value) {
  final v = value ?? '';
  if (v.isEmpty) return 'Password tidak boleh kosong';
  if (v.length < 8) return 'Password minimal 8 karakter';
  return null;
}

/// Maps a FirebaseAuthException code to a friendly Indonesian message (US01.5).
String authErrorMessage(String code) {
  switch (code) {
    case 'invalid-email':
      return 'Format email tidak valid.';
    case 'user-disabled':
      return 'Akun ini telah dinonaktifkan.';
    case 'user-not-found':
      return 'Akun tidak ditemukan.';
    case 'wrong-password':
    case 'invalid-credential':
      return 'Email atau password salah.';
    case 'email-already-in-use':
      return 'Email sudah terdaftar. Silakan login.';
    case 'weak-password':
      return 'Password terlalu lemah (minimal 8 karakter).';
    case 'network-request-failed':
      return 'Tidak ada koneksi internet.';
    case 'too-many-requests':
      return 'Terlalu banyak percobaan. Coba lagi nanti.';
    default:
      return 'Terjadi kesalahan. Coba lagi.';
  }
}
