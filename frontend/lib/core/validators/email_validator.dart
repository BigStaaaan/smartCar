class EmailValidator {
  static final RegExp _emailRegExp = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  static String? getAccountType(String? value) {
    if (value == null) return null;
    final trimmed = value.trim().toLowerCase();
    final atIndex = trimmed.lastIndexOf('@');
    if (atIndex == -1) return null;
    final domain = trimmed.substring(atIndex + 1);
    if (domain == 'edu.uiz.ac.ma') return 'STUDENT';
    if (domain == 'uiz.ac.ma') return 'STAFF';
    return null;
  }

  static bool isUniversityEmail(String? value) =>
      getAccountType(value) != null;

  static String? validateStudent(String? value) =>
      validate(value, accountType: 'STUDENT');

  static String? validateStaff(String? value) =>
      validate(value, accountType: 'STAFF');

  static String? validate(String? value, {String? accountType}) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your campus email';
    }

    final trimmed = value.trim().toLowerCase();

    if (!_emailRegExp.hasMatch(trimmed)) {
      return 'Please enter a valid email address';
    }

    final atIndex = trimmed.lastIndexOf('@');
    if (atIndex == -1) {
      return 'Please use your university email';
    }
    final domain = trimmed.substring(atIndex + 1);
    final derivedType = domain == 'edu.uiz.ac.ma'
        ? 'STUDENT'
        : domain == 'uiz.ac.ma'
            ? 'STAFF'
            : null;

    if (derivedType == null) {
      return 'Only edu.uiz.ac.ma or uiz.ac.ma are accepted';
    }
    if (accountType != null && accountType != derivedType) {
      return accountType == 'STUDENT'
          ? 'Student accounts require the edu.uiz.ac.ma domain'
          : 'Staff accounts require the uiz.ac.ma domain';
    }
    return null;
  }
}
