import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/core/ads/plan_provider.dart';

void main() {
  group('planProvider', () {
    test('returns PlanStatus.free by default', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(planProvider), PlanStatus.free);
    });

    test('can be overridden to PlanStatus.paid for testing', () {
      final container = ProviderContainer(
        overrides: [
          planProvider.overrideWithValue(PlanStatus.paid),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(planProvider), PlanStatus.paid);
    });
  });
}
