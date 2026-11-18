import 'package:flutter_riverpod/flutter_riverpod.dart';

class OnboardingState {
  final int currentPage;
  final int totalPages;
  final bool isCompleted;

  const OnboardingState({
    this.currentPage = 0,
    this.totalPages = 3,
    this.isCompleted = false,
  });

  OnboardingState copyWith({
    int? currentPage,
    int? totalPages,
    bool? isCompleted,
  }) {
    return OnboardingState(
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

class OnboardingNotifier extends StateNotifier<OnboardingState> {
  OnboardingNotifier() : super(const OnboardingState());

  void setPage(int index) {
    if (index >= 0 && index < state.totalPages) {
      state = state.copyWith(currentPage: index);
    }
  }

  void nextPage() {
    if (state.currentPage < state.totalPages - 1) {
      state = state.copyWith(currentPage: state.currentPage + 1);
    } else {
      state = state.copyWith(isCompleted: true);
    }
  }

  void previousPage() {
    if (state.currentPage > 0) {
      state = state.copyWith(currentPage: state.currentPage - 1);
    }
  }

  void complete() {
    state = state.copyWith(isCompleted: true);
  }
}

final onboardingProvider =
    StateNotifierProvider<OnboardingNotifier, OnboardingState>((ref) {
  return OnboardingNotifier();
});
