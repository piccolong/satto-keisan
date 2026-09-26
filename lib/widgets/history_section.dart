import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/history_item.dart';
import '../providers/history_provider.dart';
import 'history_tile.dart';

/// 各計算画面の「直近の履歴」欄。
/// 履歴の1件削除(取り消し可)と、そのツールの履歴の一括削除ができる。
class HistorySection extends ConsumerWidget {
  const HistorySection({
    super.key,
    required this.toolType,
    required this.onSelect,
    this.headerPadding = EdgeInsets.zero,
    this.limit = 5,
  });

  final ToolType toolType;
  final ValueChanged<HistoryItem> onSelect;
  final EdgeInsetsGeometry headerPadding;
  final int limit;

  /// 削除の確認ダイアログを表示し、「削除する」が選ばれたら true を返す。
  Future<bool> _confirmDelete(BuildContext context, String title, String message) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('削除する'),
          ),
        ],
      ),
    );
    return confirmed == true;
  }

  Future<void> _deleteItem(BuildContext context, WidgetRef ref, HistoryItem item) async {
    final confirmed = await _confirmDelete(
      context,
      'この履歴を削除',
      '${item.inputSummary}\n→ ${item.resultSummary}\n\nこの履歴を削除しますか？',
    );
    if (!confirmed || !context.mounted) return;

    final notifier = ref.read(historyProvider.notifier);
    await notifier.removeItem(item.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: const Text('履歴を1件削除しました'),
          action: SnackBarAction(
            label: '元に戻す',
            onPressed: () => notifier.restoreItem(item),
          ),
        ),
      );
  }

  Future<void> _confirmClear(BuildContext context, WidgetRef ref) async {
    final confirmed = await _confirmDelete(
      context,
      '履歴をすべて削除',
      '「${toolType.label}」の履歴をすべて削除します。この操作は取り消せません。',
    );

    if (confirmed) {
      await ref.read(historyProvider.notifier).clearByTool(toolType);
      if (context.mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(content: Text('「${toolType.label}」の履歴を削除しました')),
          );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref
        .watch(historyProvider)
        .where((e) => e.toolType == toolType)
        .take(limit)
        .toList();

    if (history.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: headerPadding,
          child: Row(
            children: [
              Expanded(
                child: Text('直近の履歴', style: Theme.of(context).textTheme.titleSmall),
              ),
              TextButton.icon(
                onPressed: () => _confirmClear(context, ref),
                icon: const Icon(Icons.delete_sweep_outlined, size: 20),
                label: const Text('すべて削除'),
              ),
            ],
          ),
        ),
        ...history.map(
          (item) => HistoryTile(
            key: ValueKey(item.id),
            item: item,
            onTap: () => onSelect(item),
            onDelete: () => _deleteItem(context, ref, item),
          ),
        ),
      ],
    );
  }
}
