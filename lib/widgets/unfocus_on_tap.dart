import 'package:flutter/material.dart';

/// 入力欄やボタン以外の何もない部分をタップしたら、入力欄の選択を外して
/// キーボードを閉じる。アプリ全体を包んで使う。
///
/// 入力欄やボタンなどのタップはそちらが優先されるため、ここでは反応しない。
class UnfocusOnTap extends StatelessWidget {
  const UnfocusOnTap({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: child,
    );
  }
}
