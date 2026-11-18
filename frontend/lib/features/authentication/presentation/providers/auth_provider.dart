import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/entities/auth_user.dart';
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
            defaultValue: 'http://10.0.2.2:3000/api/v1',
          ),
          headers: {'Content-Type': 'application/json'},
        )),
        super(const AuthState());

  final FirebaseAuthService _firebaseAuth;
  final Dio _dio;

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
      if (!user.emailVerified) {
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
        } else {
          message =
              'Unable to reach the backend. Start it with npm start on port 3000.';
        }
      }
      try {
        await _firebaseAuth.deleteCurrentAccount();
      } catch (_) {}
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
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
