import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum SplashDestination {
  home,
  profileCompletion,
  onboarding,
}

enum SplashStatus {
  initializing,
  ready,
  error,
}

class SplashState {
  final SplashStatus status;
  final SplashDestination? destination;
  final String? errorMessage;

  const SplashState({
    this.status = SplashStatus.initializing,
    this.destination,
    this.errorMessage,
  });

  SplashState copyWith({
    SplashStatus? status,
    SplashDestination? destination,
    String? errorMessage,
  }) {
    return SplashState(
      status: status ?? this.status,
      destination: destination ?? this.destination,
      errorMessage: errorMessage,
    );
  }
}

typedef ConnectivityChecker = Future<bool> Function();

Future<bool> _defaultConnectivityCheck() async {
  if (kIsWeb) return true;
  try {
    final result = await InternetAddress.lookup('google.com')
        .timeout(const Duration(seconds: 4));
    return result.isNotEmpty && result.first.rawAddress.isNotEmpty;
  } on SocketException {
    return false;
  } catch (_) {
    return false;
  }
}

class SplashNotifier extends StateNotifier<SplashState> {
  final Duration minimumSplashDuration;
  final ConnectivityChecker _checkConnectivity;

  SplashNotifier({
    this.minimumSplashDuration = const Duration(seconds: 7),
    ConnectivityChecker? checkConnectivity,
  })  : _checkConnectivity = checkConnectivity ?? _defaultConnectivityCheck,
        super(const SplashState());

  bool _isRunning = false;

  Future<void> initialize() async {
    if (_isRunning) return;
    _isRunning = true;
    state = const SplashState(status: SplashStatus.initializing);

    try {
      // Run minimum 7s logo display in parallel with connectivity & Firebase init
      final results = await Future.wait<dynamic>([
        Future<void>.delayed(minimumSplashDuration),
        _checkConnectivity(),
        _initFirebaseAndResolveDestination(),
      ]);

      final hasInternet = results[1] as bool;
      if (!hasInternet) {
        state = const SplashState(
          status: SplashStatus.error,
          errorMessage:
              'No internet connection. Please check your network and try again.',
        );
        return;
      }

      final destination = results[2] as SplashDestination;
      state = SplashState(
        status: SplashStatus.ready,
        destination: destination,
      );
    } catch (_) {
      state = const SplashState(
        status: SplashStatus.error,
        errorMessage: 'Unable to initialize SmartCar. Please try again.',
      );
    } finally {
      _isRunning = false;
    }
  }

  Future<SplashDestination> _initFirebaseAndResolveDestination() async {
    if (Firebase.apps.isEmpty) {
      try {
        await Firebase.initializeApp().timeout(const Duration(seconds: 5));
      } catch (_) {
        // Firebase options may not be bundled in local/test builds; continue gracefully.
      }
    }

    if (Firebase.apps.isNotEmpty) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final hasProfile =
            user.displayName != null && user.displayName!.trim().isNotEmpty;
        return (hasProfile && user.emailVerified)
            ? SplashDestination.home
            : SplashDestination.profileCompletion;
      }
    }

    return SplashDestination.onboarding;
  }
}

final splashProvider =
    StateNotifierProvider<SplashNotifier, SplashState>((ref) {
  return SplashNotifier();
});
