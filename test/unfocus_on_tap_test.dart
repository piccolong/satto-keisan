import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:satto_keisan/widgets/unfocus_on_tap.dart';

void main() {
  Future<void> pumpForm(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => UnfocusOnTap(child: child!),
        home: Scaffold(
          body: Column(
            children: [
              const TextField(key: Key('a')),
              const TextField(key: Key('b')),
              ElevatedButton(onPressed: () {}, child: const Text('計算する')),
              const Expanded(child: SizedBox.expand()), // 何もない部分
            ],
          ),
        ),
      ),
    );
  }

  bool hasFocus(WidgetTester tester, String key) {
    final field = tester.widget<EditableText>(
      find.descendant(of: find.byKey(Key(key)), matching: find.byType(EditableText)),
    );
    return field.focusNode.hasFocus;
  }

  testWidgets('何もない部分をタップすると入力欄の選択が外れる', (tester) async {
    await pumpForm(tester);
    await tester.tap(find.byKey(const Key('a')));
    await tester.pump();
    expect(hasFocus(tester, 'a'), isTrue);

    await tester.tapAt(const Offset(400, 500)); // 画面下部の何もない部分
    await tester.pump();
    expect(hasFocus(tester, 'a'), isFalse);
  });

  testWidgets('別の入力欄をタップするとそちらに選択が移る', (tester) async {
    await pumpForm(tester);
    await tester.tap(find.byKey(const Key('a')));
    await tester.pump();

    await tester.tap(find.byKey(const Key('b')));
    await tester.pump();
    expect(hasFocus(tester, 'a'), isFalse);
    expect(hasFocus(tester, 'b'), isTrue);
  });
}
