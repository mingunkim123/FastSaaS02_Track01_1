import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/core/ads/ad_ids.dart';

void main() {
  group('AdIds', () {
    test('banner returns the Google test banner ID by default', () {
      expect(AdIds.banner, 'ca-app-pub-3940256099942544/6300978111');
    });

    test('interstitial returns the Google test interstitial ID by default', () {
      expect(AdIds.interstitial, 'ca-app-pub-3940256099942544/1033173712');
    });
  });
}
