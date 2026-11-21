import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/auth_user.dart';
import '../../../../core/validators/email_validator.dart';
import '../../../../core/services/firebase_auth_service.dart';

class AuthState {
  final bool isLoading;
  final String? errorMessage;
  final AuthUser? user;
  final bool rememberMe;

  const AuthState({
    this.isLoading = false,
    this.errorMessage,
    this.user,
    this.rememberMe = true,
  });

  AuthState copyWith({
    bool? isLoading,
    String? errorMessage,
    AuthUser? user,
    bool? rememberMe,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      user: user ?? this.user,
      rememberMe: rememberMe ?? this.rememberMe,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier()
      : _firebaseAuth = FirebaseAuthService(),
        _dio = Dio(BaseOptions(
          baseUrl: const String.fromEnvironment(
            'API_BASE_URL',
            defaultValue: kIsWeb
                ? 'http://127.0.0.1:3000/api/v1'
                : 'http://10.0.2.2:3000/api/v1',
          ),
          headers: {'Content-Type': 'application/json'},
        )),
        super(const AuthState());

  final FirebaseAuthService _firebaseAuth;
  final Dio _dio;

  AuthUser _authUserFromResponse(
    Map<String, dynamic> data,
    String fallbackEmail,
  ) {
    final profile = data['user'] is Map
        ? Map<String, dynamic>.from(data['user'] as Map)
        : <String, dynamic>{};
    final driverProfile = profile['driverProfile'] is Map
        ? Map<String, dynamic>.from(profile['driverProfile'] as Map)
        : null;
    return AuthUser(
      id: (profile['firebaseUid'] ?? profile['id'] ?? '').toString(),
      email: (profile['email'] ?? fallbackEmail).toString(),
      displayName: profile['fullName']?.toString(),
      isVerifiedStudent: profile['universityVerified'] == true,
      isUniversityVerified: profile['universityVerified'] == true,
      role: (profile['role'] ?? 'PASSENGER').toString().toUpperCase(),
      activeMode:
          (profile['activeMode'] ?? 'PASSENGER').toString().toUpperCase(),
      driverProfile: driverProfile,
    );
  }

  void setRememberMe(bool value) {
    state = state.copyWith(rememberMe: value);
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  Future<bool> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final emailError = EmailValidator.validate(email);
    if (emailError != null) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: emailError,
      );
      return false;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final credential = await _firebaseAuth.signIn(
        email: email,
        password: password,
      );
      final user = credential.user;
      if (user == null) throw Exception('Firebase user unavailable');
      if (!user.emailVerified) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Verify your university email before continuing.',
        );
        return false;
      }

      final idToken = await _firebaseAuth.getIdToken(forceRefresh: true);
      if (idToken == null) throw Exception('Authentication token unavailable');
      await _dio.get(
        '/auth/me',
        options: Options(headers: {'Authorization': 'Bearer $idToken'}),
      );

      final authUser = AuthUser(
        id: user.uid,
        email: user.email ?? email,
        displayName: user.displayName,
        isVerifiedStudent: true,
      );

      state = state.copyWith(
        isLoading: false,
        user: authUser,
      );
      return true;
    } catch (e) {
      if (e is DioException) {
        final responseData = e.response?.data;
        String message = 'Unable to reach the SmartCar server.';
        if (responseData is Map && responseData['error'] is String) {
          message = responseData['error'] as String;
        }
        state = state.copyWith(
          isLoading: false,
          errorMessage: message,
        );
        return false;
      }
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  Future<bool> signInWithGoogle() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final credential = await _firebaseAuth.signInWithGoogle();
      final user = credential.user;
      if (user == null) throw Exception('Firebase user unavailable');
      if (!EmailValidator.isUniversityEmail(user.email)) {
        await _firebaseAuth.signOut();
        state = state.copyWith(
          isLoading: false,
          errorMessage:
              'Only university emails are allowed. Use edu.uiz.ac.ma for students or uiz.ac.ma for staff.',
        );
        return false;
      }
      final googleEmailVerified = user.emailVerified ||
          credential.additionalUserInfo?.providerId == 'google.com';
      if (!googleEmailVerified) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Your Google university email must be verified.',
        );
        return false;
      }

      final idToken = await _firebaseAuth.getIdToken(forceRefresh: true);
      if (idToken == null) throw Exception('Authentication token unavailable');
      await _dio.post(
        '/auth/google',
        options: Options(headers: {'Authorization': 'Bearer $idToken'}),
      );

      final authUser = AuthUser(
        id: user.uid,
        email: user.email ?? '',
        displayName: user.displayName,
        isVerifiedStudent: true,
      );

      state = state.copyWith(
        isLoading: false,
        user: authUser,
      );
      return true;
    } catch (e) {
      String message = 'Google Sign-In was cancelled or failed.';
      if (e is DioException) {
        final responseData = e.response?.data;
        if (responseData is Map && responseData['error'] is String) {
          message = responseData['error'] as String;
        } else if (e.type == DioExceptionType.connectionError ||
            e.type == DioExceptionType.connectionTimeout) {
          message =
              'Unable to reach the backend. Start it with npm start on port 3000.';
        }
      } else if (e is FirebaseAuthException) {
        if (e.code == 'popup-closed-by-user') {
          message = 'Google Sign-In popup was closed.';
        } else if (e.code == 'unauthorized-domain') {
          message =
              'This web domain is not authorized in Firebase Authentication.';
        } else if (e.message != null && e.message!.isNotEmpty) {
          message = e.message!;
        }
      }
      state = state.copyWith(
        isLoading: false,
        errorMessage: message,
      );
      return false;
    }
  }

  Future<bool> signUpWithEmail({
    required String fullName,
    required String university,
    required String email,
    required String password,
    required String accountType,
    bool isDriver = false,
  }) async {
    final emailError = EmailValidator.validate(email, accountType: accountType);
    if (emailError != null) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: emailError,
      );
      return false;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final credential = await _firebaseAuth.createUniversityAccount(
        email: email,
        password: password,
      );
      final user = credential.user;
      if (user == null) throw Exception('Firebase user unavailable');
      await user.updateDisplayName(fullName);
      await user.reload();

      final idToken = await _firebaseAuth.getIdToken(forceRefresh: true);
      if (idToken == null) throw Exception('Authentication token unavailable');
      await _dio.post(
        '/auth/register',
        data: {
          'fullName': fullName,
          'university': university,
          'accountType': accountType,
        },
        options: Options(headers: {'Authorization': 'Bearer $idToken'}),
      );

      final authUser = AuthUser(
        id: user.uid,
        email: user.email ?? email,
        displayName: fullName,
        isVerifiedStudent: true,
      );

      state = state.copyWith(
        isLoading: false,
        user: authUser,
      );
      return true;
    } catch (e) {
      String message = e.toString();
      if (e is DioException) {
        final responseData = e.response?.data;
        if (responseData is Map && responseData['error'] is String) {
          message = responseData['error'] as String;
        } else if (e.type == DioExceptionType.connectionError) {
          message =
              'Cannot connect to http://127.0.0.1:3000. Start the backend and allow local CORS.';
        } else if (e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.receiveTimeout) {
          message = 'The backend did not respond on port 3000.';
        } else {
          message = 'Backend request failed: ${e.message ?? e.type.name}';
        }
      }
      state = state.copyWith(
        isLoading: false,
        errorMessage: message,
      );
      return false;
    }
  }

  Future<bool> sendPasswordReset(String email) async {
    try {
      await _firebaseAuth.sendPasswordReset(email);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> refreshProfile() async {
    try {
      final idToken = await _firebaseAuth.getIdToken(forceRefresh: true);
      if (idToken == null) return false;
      final response = await _dio.get(
        '/auth/me',
        options: Options(headers: {'Authorization': 'Bearer $idToken'}),
      );
      final data = Map<String, dynamic>.from(response.data as Map);
      final firebaseUser = _firebaseAuth.currentUser;
      final authUser = _authUserFromResponse(
        data,
        firebaseUser?.email ?? state.user?.email ?? '',
      );
      state = state.copyWith(isLoading: false, errorMessage: null, user: authUser);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('smartcar_active_mode', authUser.activeMode);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _dioErrorMessage(e, 'Unable to load your profile.'),
      );
      return false;
    }
  }

  Future<bool> verifyUniversity() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final idToken = await _firebaseAuth.getIdToken(forceRefresh: true);
      if (idToken == null) throw Exception('Authentication token unavailable');
      final response = await _dio.post(
        '/auth/verify-university',
        options: Options(headers: {'Authorization': 'Bearer $idToken'}),
      );
      final data = Map<String, dynamic>.from(response.data as Map);
      final authUser = _authUserFromResponse(
        data,
        state.user?.email ?? _firebaseAuth.currentUser?.email ?? '',
      );
      state = state.copyWith(isLoading: false, errorMessage: null, user: authUser);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _dioErrorMessage(
          e,
          'University verification could not be completed.',
        ),
      );
      return false;
    }
  }

  Future<bool> activateDriver(Map<String, dynamic> driverProfile) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final idToken = await _firebaseAuth.getIdToken(forceRefresh: true);
      if (idToken == null) throw Exception('Authentication token unavailable');
      final response = await _dio.post(
        '/auth/driver/activate',
        data: driverProfile,
        options: Options(headers: {'Authorization': 'Bearer $idToken'}),
      );
      final data = Map<String, dynamic>.from(response.data as Map);
      final authUser = _authUserFromResponse(
        data,
        state.user?.email ?? _firebaseAuth.currentUser?.email ?? '',
      );
      state = state.copyWith(isLoading: false, errorMessage: null, user: authUser);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('smartcar_active_mode', 'DRIVER');
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _dioErrorMessage(
          e,
          'Driver Mode could not be activated.',
        ),
      );
      return false;
    }
  }

  Future<bool> switchMode(String activeMode) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final idToken = await _firebaseAuth.getIdToken(forceRefresh: true);
      if (idToken == null) throw Exception('Authentication token unavailable');
      final response = await _dio.put(
        '/auth/mode',
        data: {'activeMode': activeMode},
        options: Options(headers: {'Authorization': 'Bearer $idToken'}),
      );
      final data = Map<String, dynamic>.from(response.data as Map);
      final authUser = _authUserFromResponse(
        data,
        state.user?.email ?? _firebaseAuth.currentUser?.email ?? '',
      );
      state = state.copyWith(isLoading: false, errorMessage: null, user: authUser);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('smartcar_active_mode', authUser.activeMode);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _dioErrorMessage(e, 'Unable to switch mode.'),
      );
      return false;
    }
  }

  Future<void> signOut() async {
    await _firebaseAuth.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('smartcar_active_mode');
    state = const AuthState();
  }

  String _dioErrorMessage(Object error, String fallback) {
    if (error is DioException) {
      final responseData = error.response?.data;
      if (responseData is Map && responseData['error'] is String) {
        return responseData['error'] as String;
      }
    }
    return fallback;
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
