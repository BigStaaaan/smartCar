import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/auth_user.dart';

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
  AuthNotifier() : super(const AuthState());

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
      // Simulate/perform sign in logic
      await Future<void>.delayed(const Duration(milliseconds: 900));

      final user = AuthUser(
        id: 'usr_${DateTime.now().millisecondsSinceEpoch}',
        email: email,
        displayName: email.split('@').first,
        isVerifiedStudent: true,
      );

      state = state.copyWith(
        isLoading: false,
        user: user,
      );
      return true;
    } catch (e) {
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
      await Future<void>.delayed(const Duration(milliseconds: 900));

      final user = AuthUser(
        id: 'g_${DateTime.now().millisecondsSinceEpoch}',
        email: 'student@university.edu',
        displayName: 'Campus Student',
        isVerifiedStudent: true,
      );

      state = state.copyWith(
        isLoading: false,
        user: user,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Google Sign-In was cancelled or failed.',
      );
      return false;
    }
  }

  Future<bool> sendPasswordReset(String email) async {
    try {
      await Future<void>.delayed(const Duration(milliseconds: 600));
      return true;
    } catch (e) {
      return false;
    }
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
