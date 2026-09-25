import 'dart:io' show Platform;

/// 広告関連の設定を集約するクラス。
///
/// 本番リリース時は [useTestAds] を `false` にした上で、
/// `_prod` 系定数を実際のAdMob広告ユニットIDに差し替えてください。
class AdConfig {
  AdConfig._();

  /// true の間はGoogle公式のテスト広告ユニットIDを使用する。
  /// リリースビルド前に必ず false へ切り替え、本番IDを設定すること。
  static const bool useTestAds = true;

  // ── テスト用広告ユニットID(Google公式の共通テストID) ──────────────
  static const String _bannerTestAndroid =
      'ca-app-pub-3940256099942544/6300978111';
  static const String _bannerTestIOS =
      'ca-app-pub-3940256099942544/2934735716';

  static const String _interstitialTestAndroid =
      'ca-app-pub-3940256099942544/1033173712';
  static const String _interstitialTestIOS =
      'ca-app-pub-3940256099942544/4411468910';

  // ── 本番用広告ユニットID(TODO: 実際のIDに差し替える) ───────────────
  static const String _bannerProdAndroid =
      'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX';
  static const String _bannerProdIOS =
      'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX';

  static const String _interstitialProdAndroid =
      'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX';
  static const String _interstitialProdIOS =
      'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX';

  /// バナー広告のユニットID(プラットフォーム自動判定)
  static String get bannerAdUnitId {
    if (Platform.isAndroid) {
      return useTestAds ? _bannerTestAndroid : _bannerProdAndroid;
    } else if (Platform.isIOS) {
      return useTestAds ? _bannerTestIOS : _bannerProdIOS;
    }
    return _bannerTestAndroid;
  }

  /// インタースティシャル広告のユニットID(プラットフォーム自動判定)
  static String get interstitialAdUnitId {
    if (Platform.isAndroid) {
      return useTestAds ? _interstitialTestAndroid : _interstitialProdAndroid;
    } else if (Platform.isIOS) {
      return useTestAds ? _interstitialTestIOS : _interstitialProdIOS;
    }
    return _interstitialTestAndroid;
  }

  /// 「計算する」ボタンを何回タップするごとにインタースティシャル広告を
  /// 表示するか。この値を変えるだけで頻度を調整できる。
  static const int interstitialTapFrequency = 5;
}
