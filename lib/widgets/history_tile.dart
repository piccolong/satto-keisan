import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/history_item.dart';

/// 履歴1件を表示するリストアイテム。タップで入力値を再セットする。
/// [onDelete] を渡すと右端に削除ボタンを表示する。
class HistoryTile extends StatelessWidget {
  const HistoryTile({
    super.key,
    required this.item,
    required this.onTap,
    this.onDelete,
  });

  final HistoryItem item;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat('M/d HH:mm');
    final result = Text(
      item.resultSummary,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
    );

    return ListTile(
      dense: true,
      leading: const Icon(Icons.history),
      title: Text(item.inputSummary),
      subtitle: Text(formatter.format(item.timestamp)),
      trailing: onDelete == null
          ? result
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                result,
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  tooltip: 'この履歴を削除',
                  visualDensity: VisualDensity.compact,
                  onPressed: onDelete,
                ),
              ],
            ),
      onTap: onTap,
    );
  }
}
