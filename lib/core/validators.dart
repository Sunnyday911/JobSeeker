/// Shared form validators for auth screens (US01.2).
class Validators {
  Validators._();

  static final RegExp _emailRegExp = RegExp(r'^[\w.+-]+@([\w-]+\.)+[\w-]{2,}$');

  /// Validates email format.
  static String? email(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Please enter your email';
    if (!_emailRegExp.hasMatch(v)) return 'Please enter a valid email';
    return null;
  }

  /// Validates password strength: minimum 8 characters (US01.2).
  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Please enter your password';
    if (value.length < 8) return 'Password must be at least 8 characters';
    return null;
  }
}
