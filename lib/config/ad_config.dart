import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kReleaseMode;

/// 広告関連の設定を集約するクラス。
///
/// 本番の広告ユニットIDはソースに書かず、リリースビルド時に渡す:
/// `flutter build appbundle --dart-define-from-file=dart_defines/admob.prod.json`
/// (ひな形は dart_defines/admob.prod.example.json)
class AdConfig {
  AdConfig._();

  // ── 本番用広告ユニットID(ビルド時に --dart-define で渡す) ─────────────
  static const String _bannerProdAndroid = String.fromEnvironment('ADMOB_BANNER_ANDROID');
  static const String _bannerProdIOS = String.fromEnvironment('ADMOB_BANNER_IOS');
  static const String _interstitialProdAndroid =
      String.fromEnvironment('ADMOB_INTERSTITIAL_ANDROID');
  static const String _interstitialProdIOS = String.fromEnvironment('ADMOB_INTERSTITIAL_IOS');

  // ── テスト用広告ユニットID(Google公式の共通テストID) ──────────────
  static const String _bannerTestAndroid = 'ca-app-pub-3940256099942544/6300978111';
  static const String _bannerTestIOS = 'ca-app-pub-3940256099942544/2934735716';
  static const String _interstitialTestAndroid = 'ca-app-pub-3940256099942544/1033173712';
  static const String _interstitialTestIOS = 'ca-app-pub-3940256099942544/4411468910';

  /// リリースビルド以外では常にテスト広告を使う(開発中に本番広告を表示しない)。
  /// リリースビルドでも本番IDが渡されていなければテスト広告になる。
  static String _pick(String prod, String test) =>
      kReleaseMode && prod.isNotEmpty ? prod : test;

  /// バナー広告のユニットID(プラットフォーム自動判定)
  static String get bannerAdUnitId {
    if (Platform.isIOS) return _pick(_bannerProdIOS, _bannerTestIOS);
    return _pick(_bannerProdAndroid, _bannerTestAndroid);
  }

  /// インタースティシャル広告のユニットID(プラットフォーム自動判定)
  static String get interstitialAdUnitId {
    if (Platform.isIOS) return _pick(_interstitialProdIOS, _interstitialTestIOS);
    return _pick(_interstitialProdAndroid, _interstitialTestAndroid);
  }

  /// 「計算する」ボタンを何回タップするごとにインタースティシャル広告を
  /// 表示するか。この値を変えるだけで頻度を調整できる。
  static const int interstitialTapFrequency = 5;
}
