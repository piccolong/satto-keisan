import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/history_item.dart';
import '../providers/history_provider.dart';
import '../utils/calc_utils.dart';
import '../widgets/ad_banner_widget.dart';
import '../widgets/history_tile.dart';
import '../widgets/result_display.dart';

/// 割り勘計算画面。合計金額と人数から1人あたりの金額を求める。
class WarikanScreen extends ConsumerStatefulWidget {
  const WarikanScreen({super.key});

  @override
  ConsumerState<WarikanScreen> createState() => _WarikanScreenState();
}

class _WarikanScreenState extends ConsumerState<WarikanScreen> {
  final _totalController = TextEditingController();
  final _peopleController = TextEditingController();
  final _yenFormat = NumberFormat('#,###');

  RoundingMode _roundingMode = RoundingMode.round;
  int? _result;
  String? _totalError;
  String? _peopleError;

  @override
  void dispose() {
    _totalController.dispose();
    _peopleController.dispose();
    super.dispose();
  }

  void _calculate() {
    final total = CalcUtils.parseInt(_totalController.text);
    final people = CalcUtils.parseInt(_peopleController.text);

    final totalError = total == null ? '正しい金額を入力してください' : null;
    final peopleError = (people == null || people <= 0) ? '1人以上の人数を入力してください' : null;

    setState(() {
      _totalError = totalError;
      _peopleError = peopleError;
    });

    if (total == null || people == null || people <= 0) {
      setState(() => _result = null);
      return;
    }

    final perPerson = CalcUtils.calculateWarikan(
      total: total,
      people: people,
      mode: _roundingMode,
    );

    setState(() => _result = perPerson);

    InterstitialAdManager.instance.registerCalculationTap();

    ref.read(historyProvider.notifier).addItem(
      toolType: ToolType.warikan,
      inputSummary: '¥${_yenFormat.format(total)} ÷ $people人',
      resultSummary: '¥${_yenFormat.format(perPerson)}',
      inputData: {
        'total': total.toString(),
        'people': people.toString(),
        'mode': _roundingMode.name,
      },
    );
  }

  void _applyHistory(HistoryItem item) {
    final modeName = item.inputData['mode'] as String?;
    setState(() {
      _totalController.text = item.inputData['total']?.toString() ?? '';
      _peopleController.text = item.inputData['people']?.toString() ?? '';
      _roundingMode = RoundingMode.values.firstWhere(
        (m) => m.name == modeName,
        orElse: () => RoundingMode.round,
      );
      _result = null;
      _totalError = null;
      _peopleError = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final history = ref
        .watch(historyProvider)
        .where((e) => e.toolType == ToolType.warikan)
        .take(5)
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('割り勘計算')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  TextField(
                    controller: _totalController,
                    keyboardType: const TextInputType.numberWithOptions(),
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      labelText: '合計金額',
                      prefixText: '¥',
                      border: const OutlineInputBorder(),
                      errorText: _totalError,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _peopleController,
                    keyboardType: const TextInputType.numberWithOptions(),
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      labelText: '人数',
                      suffixText: '人',
                      border: const OutlineInputBorder(),
                      errorText: _peopleError,
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<RoundingMode>(
                    initialValue: _roundingMode,
                    decoration: const InputDecoration(
                      labelText: '端数処理',
                      border: OutlineInputBorder(),
                    ),
                    items: RoundingMode.values
                        .map((mode) => DropdownMenuItem(
                              value: mode,
                              child: Text(mode.label),
                            ))
                        .toList(),
                    onChanged: (mode) {
                      if (mode != null) setState(() => _roundingMode = mode);
                    },
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: _calculate,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text('計算する'),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ResultDisplay(
                    label: '1人あたり',
                    resultText: _result == null ? '' : '¥${_yenFormat.format(_result)}',
                  ),
                  if (history.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Text('直近の履歴', style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 8),
                    ...history.map(
                      (item) => HistoryTile(item: item, onTap: () => _applyHistory(item)),
                    ),
                  ],
                ],
              ),
            ),
            const AdBannerWidget(),
          ],
        ),
      ),
    );
  }
}
