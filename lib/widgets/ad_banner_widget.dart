import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../config/ad_config.dart';

/// バナー広告を表示する共通ウィジェット。
/// 各画面の下部に配置して使い回す。読み込み完了までは高さ0で場所を取らない。
class AdBannerWidget extends StatefulWidget {
  const AdBannerWidget({super.key});

  @override
  State<AdBannerWidget> createState() => _AdBannerWidgetState();
}

class _AdBannerWidgetState extends State<AdBannerWidget> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() {
    final bannerAd = BannerAd(
      adUnitId: AdConfig.bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (!mounted) {
            ad.dispose();
            return;
          }
          setState(() => _isLoaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
        },
      ),
    );
    _bannerAd = bannerAd;
    bannerAd.load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bannerAd = _bannerAd;
    if (!_isLoaded || bannerAd == null) {
      return const SizedBox.shrink();
    }
    return SafeArea(
      top: false,
      child: SizedBox(
        width: bannerAd.size.width.toDouble(),
        height: bannerAd.size.height.toDouble(),
        child: AdWidget(ad: bannerAd),
      ),
    );
  }
}

/// インタースティシャル広告の読み込み・表示・タップ回数カウントを
/// 一元管理するシングルトン。
///
/// 各計算画面の「計算する」ボタン押下時に [registerCalculationTap] を
/// 呼び出すと、[AdConfig.interstitialTapFrequency] 回に1回の頻度で
/// 自動的に広告を表示する。
class InterstitialAdManager {
  InterstitialAdManager._();

  static final InterstitialAdManager instance = InterstitialAdManager._();

  InterstitialAd? _interstitialAd;
  int _tapCount = 0;
  bool _isLoading = false;

  void _loadAd() {
    if (_isLoading || _interstitialAd != null) return;
    _isLoading = true;
    InterstitialAd.load(
      adUnitId: AdConfig.interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isLoading = false;
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _interstitialAd = null;
              _loadAd(); // 次回表示に向けて先読みしておく
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              _interstitialAd = null;
              _loadAd();
            },
          );
        },
        onAdFailedToLoad: (error) {
          _isLoading = false;
          _interstitialAd = null;
        },
      ),
    );
  }

  /// 計算実行ボタンが押されたことを通知する。
  /// 規定回数(既定5回)ごとにインタースティシャル広告を表示する。
  void registerCalculationTap() {
    // 初回呼び出し時に先読みを開始しておく。
    if (_interstitialAd == null && !_isLoading) {
      _loadAd();
    }

    _tapCount++;
    if (_tapCount >= AdConfig.interstitialTapFrequency) {
      _tapCount = 0;
      final ad = _interstitialAd;
      if (ad != null) {
        _interstitialAd = null;
        ad.show();
      }
    }
  }
}
