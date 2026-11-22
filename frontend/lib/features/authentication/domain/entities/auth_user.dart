class AuthUser {
  final String id;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final bool isVerifiedStudent;
  final bool isUniversityVerified;
  final String role;
  final String activeMode;
  final Map<String, dynamic>? driverProfile;
  final String? studentCardUrl;
  final String verificationStatus;

  const AuthUser({
    required this.id,
    required this.email,
    this.displayName,
    this.photoUrl,
    this.isVerifiedStudent = false,
    this.isUniversityVerified = false,
    this.role = 'PASSENGER',
    this.activeMode = 'PASSENGER',
    this.driverProfile,
    this.studentCardUrl,
    this.verificationStatus = 'PENDING',
  });
}
