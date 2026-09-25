import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/history_item.dart';

/// 履歴1件を表示するリストアイテム。タップで入力値を再セットする。
class HistoryTile extends StatelessWidget {
  const HistoryTile({
    super.key,
    required this.item,
    required this.onTap,
  });

  final HistoryItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat('M/d HH:mm');

    return ListTile(
      dense: true,
      leading: const Icon(Icons.history),
      title: Text(item.inputSummary),
      subtitle: Text(formatter.format(item.timestamp)),
      trailing: Text(
        item.resultSummary,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
      ),
      onTap: onTap,
    );
  }
}
