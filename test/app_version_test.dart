import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:satto_keisan/screens/settings_screen.dart';

void main() {
  test('設定画面のバージョン表示が pubspec.yaml の version と一致する', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final match = RegExp(r'^version:\s*([^+\s]+)', multiLine: true).firstMatch(pubspec);
    expect(match, isNotNull);
    expect(appVersion, match!.group(1));
  });
}
