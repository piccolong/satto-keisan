// 基本的なスモークテスト。
// ホーム画面が起動し、タイトルと5つのツールカードが表示されることを確認する。

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:satto_keisan/main.dart';

void main() {
  testWidgets('ホーム画面にタイトルと5つのツールが表示される', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    await tester.pumpAndSettle();

    expect(find.text('サッと計算'), findsOneWidget);
    expect(find.text('割り勘計算'), findsOneWidget);
    expect(find.text('日数・日付計算'), findsOneWidget);
    expect(find.text('単位変換'), findsOneWidget);

    // グリッドは端末サイズによって一部のカードが画面外になるためスクロールする。
    await tester.dragUntilVisible(
      find.text('パーセント計算'),
      find.byType(GridView),
      const Offset(0, -200),
    );
    await tester.pumpAndSettle();

    expect(find.text('消費税計算'), findsOneWidget);
    expect(find.text('パーセント計算'), findsOneWidget);
  });

  testWidgets('アプリの言語は日本語(漢字を日本語の字形で表示するため)', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    await tester.pumpAndSettle();

    final context = tester.element(find.text('サッと計算'));
    expect(Localizations.localeOf(context), const Locale('ja', 'JP'));
    expect(MaterialLocalizations.of(context).cancelButtonLabel, 'キャンセル');
  });
}
