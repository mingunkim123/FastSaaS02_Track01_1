import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Current subscription plan status of the user.
enum PlanStatus { free, paid }

/// Returns the current user's plan.
///
/// Current behavior: all users treated as [PlanStatus.free] (backend plan
/// field not available yet). When the backend exposes plan data, replace
/// the body of this provider to query it — consumers (`AdBanner`,
/// `AdInterstitialTrigger`) do not need to change.
///
/// Dev override: build with `--dart-define=PREMIUM=true` to simulate the
/// paid plan locally (hides all ads) — useful for UX verification.
final planProvider = Provider<PlanStatus>((ref) {
  const isPremium = bool.fromEnvironment('PREMIUM', defaultValue: false);
  return isPremium ? PlanStatus.paid : PlanStatus.free;
});
