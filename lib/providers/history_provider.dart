import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/history_item.dart';

const String _prefsKey = 'history_items_v1';

/// 全ツール共通の計算履歴を保持する StateNotifier。
/// 新しい順に並び、ツールごとに直近5件を取得できる。
class HistoryNotifier extends StateNotifier<List<HistoryItem>> {
  HistoryNotifier() : super([]) {
    _load();
  }

  static const int _maxItemsPerTool = 20; // 保存上限(肥大化防止)

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null || raw.isEmpty) return;
    try {
      final list = jsonDecode(raw) as List;
      state = list
          .map((e) => HistoryItem.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      // 破損データは無視して空のまま開始する。
    }
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(state.map((e) => e.toJson()).toList());
    await prefs.setString(_prefsKey, raw);
  }

  /// 履歴を1件追加する。同一ツールの件数が上限を超えたら古いものを削除する。
  Future<void> addItem({
    required ToolType toolType,
    required String inputSummary,
    required String resultSummary,
    Map<String, dynamic> inputData = const {},
  }) async {
    final newItem = HistoryItem(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      toolType: toolType,
      inputSummary: inputSummary,
      resultSummary: resultSummary,
      timestamp: DateTime.now(),
      inputData: inputData,
    );

    final sameTool = state.where((e) => e.toolType == toolType).toList();
    final others = state.where((e) => e.toolType != toolType).toList();
    final updatedSameTool = [newItem, ...sameTool].take(_maxItemsPerTool).toList();

    state = [...updatedSameTool, ...others]
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    await _persist();
  }

  /// 指定ツールの直近 [limit] 件を取得する(新しい順)。
  List<HistoryItem> getByTool(ToolType toolType, {int limit = 5}) {
    return state.where((e) => e.toolType == toolType).take(limit).toList();
  }

  /// 指定IDの履歴を1件削除する。
  Future<void> removeItem(String id) async {
    state = state.where((e) => e.id != id).toList();
    await _persist();
  }

  /// 削除した履歴を元に戻す(削除の取り消し用)。
  Future<void> restoreItem(HistoryItem item) async {
    if (state.any((e) => e.id == item.id)) return;
    state = [...state, item]..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    await _persist();
  }

  /// 指定ツールの履歴をすべて削除する。他のツールの履歴は残す。
  Future<void> clearByTool(ToolType toolType) async {
    state = state.where((e) => e.toolType != toolType).toList();
    await _persist();
  }

  /// 履歴を全件削除する。
  Future<void> clearAll() async {
    state = [];
    await _persist();
  }
}

final historyProvider =
    StateNotifierProvider<HistoryNotifier, List<HistoryItem>>((ref) {
  return HistoryNotifier();
});
