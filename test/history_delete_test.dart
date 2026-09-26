import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:satto_keisan/models/history_item.dart';
import 'package:satto_keisan/providers/history_provider.dart';
import 'package:satto_keisan/widgets/history_section.dart';

Future<ProviderContainer> _containerWithHistory() async {
  final container = ProviderContainer();
  final notifier = container.read(historyProvider.notifier);
  await Future<void>.delayed(Duration.zero); // 保存済み履歴の読み込み完了を待つ
  await notifier.addItem(toolType: ToolType.taxCalc, inputSummary: '税1', resultSummary: '¥110');
  await Future<void>.delayed(const Duration(milliseconds: 2)); // IDと時刻を重複させない
  await notifier.addItem(toolType: ToolType.taxCalc, inputSummary: '税2', resultSummary: '¥220');
  await Future<void>.delayed(const Duration(milliseconds: 2));
  await notifier.addItem(toolType: ToolType.warikan, inputSummary: '割1', resultSummary: '¥750');
  return container;
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('HistoryNotifier', () {
    test('removeItem は指定した1件だけを削除する', () async {
      final container = await _containerWithHistory();
      addTearDown(container.dispose);
      final target = container.read(historyProvider).firstWhere((e) => e.inputSummary == '税1');

      await container.read(historyProvider.notifier).removeItem(target.id);

      expect(
        container.read(historyProvider).map((e) => e.inputSummary),
        unorderedEquals(['税2', '割1']),
      );
    });

    test('restoreItem で削除した履歴が元の位置に戻る', () async {
      final container = await _containerWithHistory();
      addTearDown(container.dispose);
      final notifier = container.read(historyProvider.notifier);
      final before = container.read(historyProvider).map((e) => e.id).toList();
      final target = container.read(historyProvider)[1];

      await notifier.removeItem(target.id);
      await notifier.restoreItem(target);

      expect(container.read(historyProvider).map((e) => e.id).toList(), before);
    });

    test('clearByTool は指定ツールの履歴だけを削除する', () async {
      final container = await _containerWithHistory();
      addTearDown(container.dispose);

      await container.read(historyProvider.notifier).clearByTool(ToolType.taxCalc);

      expect(container.read(historyProvider).map((e) => e.inputSummary), ['割1']);
    });

    test('削除結果は保存され、再読み込み後も反映される', () async {
      final container = await _containerWithHistory();
      await container.read(historyProvider.notifier).clearByTool(ToolType.warikan);
      container.dispose();

      final reloaded = ProviderContainer();
      addTearDown(reloaded.dispose);
      reloaded.read(historyProvider);
      await Future<void>.delayed(Duration.zero);

      expect(
        reloaded.read(historyProvider).map((e) => e.inputSummary),
        unorderedEquals(['税1', '税2']),
      );
    });
  });

  group('HistorySection', () {
    Future<ProviderContainer> pumpSection(WidgetTester tester) async {
      final container = await tester.runAsync(_containerWithHistory);
      addTearDown(container!.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: HistorySection(toolType: ToolType.taxCalc, onSelect: (_) {}),
            ),
          ),
        ),
      );
      return container;
    }

    testWidgets('削除ボタンは確認後に1件削除し、元に戻すで復元できる', (tester) async {
      await pumpSection(tester);
      expect(find.text('税1'), findsOneWidget);
      expect(find.text('税2'), findsOneWidget);
      expect(find.text('割1'), findsNothing);

      await tester.tap(find.byTooltip('この履歴を削除').first); // 新しい順なので「税2」
      await tester.pumpAndSettle();
      expect(find.text('税2\n→ ¥220\n\nこの履歴を削除しますか？'), findsOneWidget);
      expect(find.text('税2'), findsOneWidget); // 確認中はまだ消えない

      await tester.tap(find.text('削除する'));
      await tester.pumpAndSettle();
      expect(find.text('税2'), findsNothing);
      expect(find.text('税1'), findsOneWidget);
      expect(find.text('履歴を1件削除しました'), findsOneWidget);

      await tester.tap(find.text('元に戻す'));
      await tester.pumpAndSettle();
      expect(find.text('税2'), findsOneWidget);
    });

    testWidgets('1件削除をキャンセルすると何も消えない', (tester) async {
      final container = await pumpSection(tester);

      await tester.tap(find.byTooltip('この履歴を削除').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('キャンセル'));
      await tester.pumpAndSettle();

      expect(container.read(historyProvider), hasLength(3));
      expect(find.text('税2'), findsOneWidget);
      expect(find.text('履歴を1件削除しました'), findsNothing);
    });

    testWidgets('すべて削除は確認後にそのツールの履歴だけを消す', (tester) async {
      final container = await pumpSection(tester);

      await tester.tap(find.text('すべて削除'));
      await tester.pumpAndSettle();
      expect(find.text('「消費税計算」の履歴をすべて削除します。この操作は取り消せません。'), findsOneWidget);

      await tester.tap(find.text('削除する'));
      await tester.pumpAndSettle();

      expect(find.text('直近の履歴'), findsNothing);
      expect(container.read(historyProvider).map((e) => e.inputSummary), ['割1']);
    });

    testWidgets('すべて削除をキャンセルすると何も消えない', (tester) async {
      final container = await pumpSection(tester);

      await tester.tap(find.text('すべて削除'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('キャンセル'));
      await tester.pumpAndSettle();

      expect(container.read(historyProvider), hasLength(3));
      expect(find.text('税1'), findsOneWidget);
    });
  });
}
