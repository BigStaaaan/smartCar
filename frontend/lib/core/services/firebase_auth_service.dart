import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class FirebaseAuthService {
  FirebaseAuthService({FirebaseAuth? auth}) : _auth = auth;

  final FirebaseAuth? _auth;
  FirebaseAuth get _firebaseAuth => _auth ?? FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  bool _googleInitialized = false;

  Future<void> _ensureGoogleInitialized() async {
    if (_googleInitialized) return;
    await _googleSignIn.initialize();
    _googleInitialized = true;
  }

  User? get currentUser => _firebaseAuth.currentUser;

  Future<UserCredential> createUniversityAccount({
    required String email,
    required String password,
  }) async {
    final credential = await _firebaseAuth.createUserWithEmailAndPassword(
      email: email.trim().toLowerCase(),
      password: password,
    );
    await credential.user?.sendEmailVerification();
    return credential;
  }

  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) {
    return _firebaseAuth.signInWithEmailAndPassword(
      email: email.trim().toLowerCase(),
      password: password,
    );
  }

  Future<UserCredential> signInWithGoogle() async {
    if (kIsWeb) {
      final googleProvider = GoogleAuthProvider();
      googleProvider.setCustomParameters({
        'prompt': 'select_account',
      });
      return _firebaseAuth.signInWithPopup(googleProvider);
    }

    await _ensureGoogleInitialized();
    final googleUser = await _googleSignIn.authenticate();
    final googleAuth = googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
    );
    return _firebaseAuth.signInWithCredential(credential);
  }

  Future<void> sendPasswordReset(String email) {
    return _firebaseAuth.sendPasswordResetEmail(
      email: email.trim().toLowerCase(),
    );
  }

  Future<String?> getIdToken({bool forceRefresh = false}) async {
    return _firebaseAuth.currentUser?.getIdToken(forceRefresh);
  }

  Future<void> reloadAndCheckVerification() async {
    await _firebaseAuth.currentUser?.reload();
  }

  Future<void> resendVerificationEmail() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'no-current-user',
        message: 'No signed-in account is available.',
      );
    }
    if (user.emailVerified) return;
    await user.sendEmailVerification();
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _firebaseAuth.signOut();
  }

  Future<void> deleteCurrentAccount() async {
    await _firebaseAuth.currentUser?.delete();
  }
}
