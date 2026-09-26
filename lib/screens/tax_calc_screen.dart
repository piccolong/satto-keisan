import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/history_item.dart';
import '../providers/history_provider.dart';
import '../utils/calc_utils.dart';
import '../widgets/ad_banner_widget.dart';
import '../widgets/history_section.dart';
import '../widgets/result_display.dart';

/// 消費税計算画面。内税/外税の切り替えと任意の税率で税込み・税抜き金額を求める。
class TaxCalcScreen extends ConsumerStatefulWidget {
  const TaxCalcScreen({super.key});

  @override
  ConsumerState<TaxCalcScreen> createState() => _TaxCalcScreenState();
}

class _TaxCalcScreenState extends ConsumerState<TaxCalcScreen> {
  final _amountController = TextEditingController();
  final _rateController = TextEditingController(text: '10');
  final _yenFormat = NumberFormat('#,##0.##');

  /// true: 入力金額は税込み(内税)として扱う / false: 税抜き(外税)として扱う
  bool _isTaxInclusive = false;

  double? _resultAmount;
  double? _taxAmount;
  String? _amountError;
  String? _rateError;

  @override
  void dispose() {
    _amountController.dispose();
    _rateController.dispose();
    super.dispose();
  }

  void _calculate() {
    final amount = CalcUtils.parseDouble(_amountController.text);
    final rate = CalcUtils.parseDouble(_rateController.text);

    final amountError = amount == null ? '正しい金額を入力してください' : null;
    final rateError = (rate == null || rate < 0) ? '正しい税率を入力してください' : null;

    setState(() {
      _amountError = amountError;
      _rateError = rateError;
    });

    if (amount == null || rate == null || rate < 0) {
      setState(() {
        _resultAmount = null;
        _taxAmount = null;
      });
      return;
    }

    double resultAmount;
    double taxAmount;
    if (_isTaxInclusive) {
      // 入力=税込み → 税抜きを求める
      resultAmount = CalcUtils.taxInclusiveToExclusive(amount, rate);
      taxAmount = amount - resultAmount;
    } else {
      // 入力=税抜き → 税込みを求める
      resultAmount = CalcUtils.taxExclusiveToInclusive(amount, rate);
      taxAmount = resultAmount - amount;
    }

    setState(() {
      _resultAmount = resultAmount;
      _taxAmount = taxAmount;
    });

    InterstitialAdManager.instance.registerCalculationTap();

    ref.read(historyProvider.notifier).addItem(
      toolType: ToolType.taxCalc,
      inputSummary:
          '¥${_yenFormat.format(amount)}(${_isTaxInclusive ? "税込" : "税抜"}) 税率${_yenFormat.format(rate)}%',
      resultSummary: '¥${_yenFormat.format(resultAmount)}',
      inputData: {
        'amount': amount.toString(),
        'rate': rate.toString(),
        'isTaxInclusive': _isTaxInclusive.toString(),
      },
    );
  }

  void _applyHistory(HistoryItem item) {
    setState(() {
      _amountController.text = item.inputData['amount']?.toString() ?? '';
      _rateController.text = item.inputData['rate']?.toString() ?? '10';
      _isTaxInclusive = item.inputData['isTaxInclusive'] == 'true';
      _resultAmount = null;
      _taxAmount = null;
      _amountError = null;
      _rateError = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('消費税計算')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  TextField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: '金額',
                      prefixText: '¥',
                      border: const OutlineInputBorder(),
                      errorText: _amountError,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('入力金額の種別'),
                    subtitle: Text(_isTaxInclusive ? '内税(税込み金額として入力)' : '外税(税抜き金額として入力)'),
                    value: _isTaxInclusive,
                    onChanged: (value) => setState(() => _isTaxInclusive = value),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _rateController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: '税率',
                      suffixText: '%',
                      border: const OutlineInputBorder(),
                      errorText: _rateError,
                    ),
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
                    label: _isTaxInclusive ? '税抜き金額' : '税込み金額',
                    resultText: _resultAmount == null ? '' : '¥${_yenFormat.format(_resultAmount)}',
                  ),
                  if (_taxAmount != null) ...[
                    const SizedBox(height: 12),
                    Center(
                      child: Text(
                        '消費税額: ¥${_yenFormat.format(_taxAmount)}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                  HistorySection(
                    toolType: ToolType.taxCalc,
                    onSelect: _applyHistory,
                    headerPadding: const EdgeInsets.only(top: 16),
                  ),
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
