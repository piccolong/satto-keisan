import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'providers/settings_provider.dart';
import 'screens/home_screen.dart';
import 'widgets/unfocus_on_tap.dart';

/// テーマカラーのシード。ブランドカラーが決まったらここを変更する。
const Color seedColor = Colors.teal;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // 起動速度を優先するため await せずバックグラウンドで初期化する。
  // 広告SDKの初期化完了を待たなくても最初のフレームは描画できる。
  MobileAds.instance.initialize();
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return MaterialApp(
      title: 'サッと計算',
      debugShowCheckedModeBanner: false,
      // 日本語を指定しないと、端末によっては漢字が中国語の字形になる(例:「直」)
      locale: const Locale('ja', 'JP'),
      supportedLocales: const [Locale('ja', 'JP')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      // どの画面でも、何もない部分をタップしたら入力欄の選択を外す
      builder: (context, child) => UnfocusOnTap(child: child!),
      themeMode: settings.themeMode,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: seedColor,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: seedColor,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
