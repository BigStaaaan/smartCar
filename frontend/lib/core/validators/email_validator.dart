class EmailValidator {
  static final RegExp _emailRegExp = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  static String? validate(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your campus email';
    }

    final trimmed = value.trim().toLowerCase();

    if (!_emailRegExp.hasMatch(trimmed)) {
      return 'Please enter a valid email address';
    }

    // Must be a university email (.edu, .ac.ma, or university domain)
    final isEdu = trimmed.endsWith('.edu') ||
        trimmed.contains('.edu.') ||
        trimmed.endsWith('.ac.ma') ||
        trimmed.contains('uiz.ac.ma');

    if (!isEdu) {
      return 'Please use your verified .edu campus email';
    }

    return null;
  }
}
