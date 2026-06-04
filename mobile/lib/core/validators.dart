/// Reusable form validators for the Mongez app.
///
/// All validators return `null` on success or a localized message string on
/// failure. Pass them directly to `CustomFormField.validator`:
///
/// ```dart
/// CustomFormField(
///   controller: _emailCtrl,
///   validator: Validators.email(lang.emailInvalid),
/// )
/// ```
class Validators {
  Validators._();

  /// Combine multiple validators — returns the first non-null error.
  static String? Function(String?) compose(
    List<String? Function(String?)> validators,
  ) {
    return (value) {
      for (final v in validators) {
        final err = v(value);
        if (err != null) return err;
      }
      return null;
    };
  }

  static String? Function(String?) required(String message) {
    return (value) => (value == null || value.trim().isEmpty) ? message : null;
  }

  static String? Function(String?) minLength(int n, String message) {
    return (value) => (value == null || value.length < n) ? message : null;
  }

  static String? Function(String?) maxLength(int n, String message) {
    return (value) =>
        (value != null && value.length > n) ? message : null;
  }

  static final RegExp _emailRe =
      RegExp(r"^[\w.+-]+@[\w-]+\.[\w.-]+$");

  static String? Function(String?) email(String message) {
    return (value) {
      if (value == null || value.isEmpty) return null; // optional by default
      return _emailRe.hasMatch(value) ? null : message;
    };
  }

  /// Accepts +, digits, spaces, parens, dashes; 7-20 chars (matches backend regex).
  static final RegExp _phoneRe = RegExp(r'^\+?[0-9 ()\-]{7,20}$');

  static String? Function(String?) phone(String message) {
    return (value) {
      if (value == null || value.isEmpty) return message;
      return _phoneRe.hasMatch(value.trim()) ? null : message;
    };
  }

  /// Stars must be 1..5
  static String? stars(int? value) {
    if (value == null) return 'Required';
    if (value < 1 || value > 5) return 'Must be 1–5';
    return null;
  }
}
