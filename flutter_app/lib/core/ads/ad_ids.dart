/// AdMob ad unit IDs. Uses Google's official test IDs by default; switches
/// to production IDs when built with `--dart-define=ADMOB_MODE=prod`.
///
/// Replace `_prodBanner` and `_prodInterstitial` once AdMob account is
/// created and ad units are generated.
class AdIds {
  static const _mode =
      String.fromEnvironment('ADMOB_MODE', defaultValue: 'test');

  // Google official test ad unit IDs for Android.
  // https://developers.google.com/admob/flutter/test-ads
  static const _testBanner = 'ca-app-pub-3940256099942544/6300978111';
  static const _testInterstitial = 'ca-app-pub-3940256099942544/1033173712';

  // Placeholders — replace after creating real ad units in AdMob console.
  static const _prodBanner = 'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX';
  static const _prodInterstitial = 'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX';

  static String get banner => _mode == 'prod' ? _prodBanner : _testBanner;
  static String get interstitial =>
      _mode == 'prod' ? _prodInterstitial : _testInterstitial;
}
