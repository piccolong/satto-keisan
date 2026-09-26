import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/history_item.dart';
import '../providers/history_provider.dart';
import '../utils/calc_utils.dart';
import '../widgets/ad_banner_widget.dart';
import '../widgets/history_section.dart';
import '../widgets/result_display.dart';

/// パーセント計算画面。タブで「割引後価格」「増減率」を切り替える。
class PercentCalcScreen extends ConsumerStatefulWidget {
  const PercentCalcScreen({super.key});

  @override
  ConsumerState<PercentCalcScreen> createState() => _PercentCalcScreenState();
}

class _PercentCalcScreenState extends ConsumerState<PercentCalcScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _numFormat = NumberFormat('#,##0.##');

  // 割引後価格
  final _originalPriceController = TextEditingController();
  final _discountController = TextEditingController();
  double? _discountResult;
  String? _originalPriceError;
  String? _discountError;

  // 増減率
  final _oldValueController = TextEditingController();
  final _newValueController = TextEditingController();
  double? _changeRateResult;
  String? _oldValueError;
  String? _newValueError;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _originalPriceController.dispose();
    _discountController.dispose();
    _oldValueController.dispose();
    _newValueController.dispose();
    super.dispose();
  }

  void _calculateDiscount() {
    final original = CalcUtils.parseDouble(_originalPriceController.text);
    final discount = CalcUtils.parseDouble(_discountController.text);

    setState(() {
      _originalPriceError = original == null ? '正しい価格を入力してください' : null;
      _discountError = discount == null ? '正しい割引率を入力してください' : null;
    });

    if (original == null || discount == null) {
      setState(() => _discountResult = null);
      return;
    }

    final result = CalcUtils.discountedPrice(original, discount);
    setState(() => _discountResult = result);

    InterstitialAdManager.instance.registerCalculationTap();

    ref.read(historyProvider.notifier).addItem(
      toolType: ToolType.percentCalc,
      inputSummary: '¥${_numFormat.format(original)} を${_numFormat.format(discount)}%引き',
      resultSummary: '¥${_numFormat.format(result)}',
      inputData: {
        'mode': 'discount',
        'original': original.toString(),
        'discount': discount.toString(),
      },
    );
  }

  void _calculateChangeRate() {
    final oldValue = CalcUtils.parseDouble(_oldValueController.text);
    final newValue = CalcUtils.parseDouble(_newValueController.text);

    setState(() {
      _oldValueError = oldValue == null ? '正しい値を入力してください' : null;
      _newValueError = newValue == null ? '正しい値を入力してください' : null;
    });

    if (oldValue == null || newValue == null) {
      setState(() => _changeRateResult = null);
      return;
    }

    final result = CalcUtils.changeRate(oldValue, newValue);
    setState(() => _changeRateResult = result);

    InterstitialAdManager.instance.registerCalculationTap();

    ref.read(historyProvider.notifier).addItem(
      toolType: ToolType.percentCalc,
      inputSummary: '${_numFormat.format(oldValue)} → ${_numFormat.format(newValue)}',
      resultSummary: '${result >= 0 ? '+' : ''}${_numFormat.format(result)}%',
      inputData: {
        'mode': 'changeRate',
        'oldValue': oldValue.toString(),
        'newValue': newValue.toString(),
      },
    );
  }

  void _applyHistory(HistoryItem item) {
    final mode = item.inputData['mode'] as String?;
    if (mode == 'discount') {
      setState(() {
        _tabController.index = 0;
        _originalPriceController.text = item.inputData['original']?.toString() ?? '';
        _discountController.text = item.inputData['discount']?.toString() ?? '';
        _discountResult = null;
        _originalPriceError = null;
        _discountError = null;
      });
    } else {
      setState(() {
        _tabController.index = 1;
        _oldValueController.text = item.inputData['oldValue']?.toString() ?? '';
        _newValueController.text = item.inputData['newValue']?.toString() ?? '';
        _changeRateResult = null;
        _oldValueError = null;
        _newValueError = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('パーセント計算'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '割引後価格'),
            Tab(text: '増減率'),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildDiscountTab(),
                  _buildChangeRateTab(),
                ],
              ),
            ),
            const AdBannerWidget(),
          ],
        ),
      ),
    );
  }

  /// 結果の下に表示する履歴欄(他の計算画面と同じ位置)。全タブ共通の履歴を表示する。
  Widget _buildHistory() {
    return HistorySection(
      toolType: ToolType.percentCalc,
      onSelect: _applyHistory,
      headerPadding: const EdgeInsets.only(top: 16),
    );
  }

  Widget _buildDiscountTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        TextField(
          controller: _originalPriceController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: '元の価格',
            prefixText: '¥',
            border: const OutlineInputBorder(),
            errorText: _originalPriceError,
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _discountController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: '割引率',
            suffixText: '%',
            border: const OutlineInputBorder(),
            errorText: _discountError,
          ),
        ),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: _calculateDiscount,
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text('計算する'),
          ),
        ),
        const SizedBox(height: 24),
        ResultDisplay(
          label: '割引後の価格',
          resultText: _discountResult == null ? '' : '¥${_numFormat.format(_discountResult)}',
        ),
        _buildHistory(),
      ],
    );
  }

  Widget _buildChangeRateTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        TextField(
          controller: _oldValueController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
          decoration: InputDecoration(
            labelText: '元の値',
            border: const OutlineInputBorder(),
            errorText: _oldValueError,
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _newValueController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
          decoration: InputDecoration(
            labelText: '新しい値',
            border: const OutlineInputBorder(),
            errorText: _newValueError,
          ),
        ),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: _calculateChangeRate,
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text('計算する'),
          ),
        ),
        const SizedBox(height: 24),
        ResultDisplay(
          label: '変化率',
          resultText: _changeRateResult == null
              ? ''
              : '${_changeRateResult! >= 0 ? '+' : ''}${_numFormat.format(_changeRateResult)}%',
        ),
        _buildHistory(),
      ],
    );
  }
}
