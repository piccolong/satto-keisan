import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/history_item.dart';
import '../providers/history_provider.dart';
import '../providers/settings_provider.dart';
import '../utils/calc_utils.dart';
import '../widgets/ad_banner_widget.dart';
import '../widgets/history_tile.dart';
import '../widgets/result_display.dart';

/// 単位変換画面。カテゴリ・単位を選ぶとボタン不要でリアルタイムに変換する。
class UnitConvertScreen extends ConsumerStatefulWidget {
  const UnitConvertScreen({super.key});

  @override
  ConsumerState<UnitConvertScreen> createState() => _UnitConvertScreenState();
}

class _UnitConvertScreenState extends ConsumerState<UnitConvertScreen> {
  final _valueController = TextEditingController();
  final _numFormat = NumberFormat('#,##0.######');

  UnitCategory _category = UnitCategory.length;
  late String _fromUnit;
  late String _toUnit;
  double? _result;
  bool _hasLoggedForCurrentInput = false;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(settingsProvider);
    _fromUnit = settings.defaultLengthUnit;
    _toUnit = CalcUtils.unitsByCategory[UnitCategory.length]!
        .firstWhere((u) => u != _fromUnit, orElse: () => _fromUnit);
  }

  @override
  void dispose() {
    _valueController.dispose();
    super.dispose();
  }

  void _onCategoryChanged(UnitCategory category) {
    final units = CalcUtils.unitsByCategory[category]!;
    setState(() {
      _category = category;
      _fromUnit = units.first;
      _toUnit = units.length > 1 ? units[1] : units.first;
      _result = null;
    });
    _convert();
  }

  void _swapUnits() {
    setState(() {
      final temp = _fromUnit;
      _fromUnit = _toUnit;
      _toUnit = temp;
    });
    _convert();
    _commitToHistory();
  }

  void _convert() {
    final value = CalcUtils.parseDouble(_valueController.text);
    if (value == null) {
      setState(() => _result = null);
      return;
    }
    final result = CalcUtils.convertUnit(
      category: _category,
      from: _fromUnit,
      to: _toUnit,
      value: value,
    );
    setState(() => _result = result);
    _hasLoggedForCurrentInput = false;
  }

  /// キーボードの完了操作時などに履歴へ記録する(リアルタイム変換中は
  /// 1キー入力ごとに記録すると履歴が埋まってしまうため、確定時のみ)。
  void _commitToHistory() {
    if (_hasLoggedForCurrentInput) return;
    final value = CalcUtils.parseDouble(_valueController.text);
    if (value == null || _result == null) return;
    _hasLoggedForCurrentInput = true;

    InterstitialAdManager.instance.registerCalculationTap();

    ref.read(historyProvider.notifier).addItem(
      toolType: ToolType.unitConvert,
      inputSummary: '${_numFormat.format(value)}$_fromUnit → $_toUnit',
      resultSummary: '${_numFormat.format(_result)}$_toUnit',
      inputData: {
        'category': _category.name,
        'from': _fromUnit,
        'to': _toUnit,
        'value': value.toString(),
      },
    );
  }

  void _applyHistory(HistoryItem item) {
    final categoryName = item.inputData['category'] as String?;
    final category = UnitCategory.values.firstWhere(
      (c) => c.name == categoryName,
      orElse: () => UnitCategory.length,
    );
    setState(() {
      _category = category;
      _fromUnit = item.inputData['from']?.toString() ?? CalcUtils.unitsByCategory[category]!.first;
      _toUnit = item.inputData['to']?.toString() ?? CalcUtils.unitsByCategory[category]!.first;
      _valueController.text = item.inputData['value']?.toString() ?? '';
    });
    _convert();
  }

  @override
  Widget build(BuildContext context) {
    final units = CalcUtils.unitsByCategory[_category]!;
    final history = ref
        .watch(historyProvider)
        .where((e) => e.toolType == ToolType.unitConvert)
        .take(5)
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('単位変換')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  DropdownButtonFormField<UnitCategory>(
                    initialValue: _category,
                    decoration: const InputDecoration(
                      labelText: 'カテゴリ',
                      border: OutlineInputBorder(),
                    ),
                    items: UnitCategory.values
                        .map((c) => DropdownMenuItem(value: c, child: Text(c.label)))
                        .toList(),
                    onChanged: (c) {
                      if (c != null) _onCategoryChanged(c);
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _valueController,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true, signed: true),
                    decoration: const InputDecoration(
                      labelText: '変換元の値',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (_) => _convert(),
                    onEditingComplete: () {
                      _commitToHistory();
                      FocusScope.of(context).unfocus();
                    },
                    onSubmitted: (_) => _commitToHistory(),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _fromUnit,
                          decoration: const InputDecoration(
                            labelText: '変換元',
                            border: OutlineInputBorder(),
                          ),
                          items: units
                              .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                              .toList(),
                          onChanged: (u) {
                            if (u != null) {
                              setState(() => _fromUnit = u);
                              _convert();
                              _commitToHistory();
                            }
                          },
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.swap_horiz),
                        tooltip: '単位を入れ替え',
                        onPressed: _swapUnits,
                      ),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _toUnit,
                          decoration: const InputDecoration(
                            labelText: '変換先',
                            border: OutlineInputBorder(),
                          ),
                          items: units
                              .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                              .toList(),
                          onChanged: (u) {
                            if (u != null) {
                              setState(() => _toUnit = u);
                              _convert();
                              _commitToHistory();
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  ResultDisplay(
                    label: '変換結果',
                    resultText: _result == null ? '' : '${_numFormat.format(_result)}$_toUnit',
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
