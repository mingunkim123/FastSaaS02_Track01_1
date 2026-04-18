import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ============================================================
// [온보딩 완료 프로바이더] onboarding_provider.dart
// 사용자가 온보딩을 이미 봤는지 여부를 SharedPreferences로 영속화.
// goRouter redirect가 이 값을 참조해 첫 실행 시 /onboarding으로 보냄.
// ============================================================

const _prefsKey = 'app.onboarding.completed';

class OnboardingController extends StateNotifier<AsyncValue<bool>> {
  OnboardingController() : super(const AsyncValue.loading()) {
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      state = AsyncValue.data(prefs.getBool(_prefsKey) ?? false);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> markCompleted() async {
    state = const AsyncValue.data(true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKey, true);
  }

  /// 테스트·디버그용. 온보딩을 다시 보게 하려면 호출.
  Future<void> reset() async {
    state = const AsyncValue.data(false);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
  }
}

final onboardingCompletedProvider =
    StateNotifierProvider<OnboardingController, AsyncValue<bool>>((ref) {
  return OnboardingController();
});
