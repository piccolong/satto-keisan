import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/history_item.dart';
import '../providers/history_provider.dart';
import '../utils/calc_utils.dart';
import '../widgets/ad_banner_widget.dart';
import '../widgets/history_section.dart';
import '../widgets/result_display.dart';

/// 日付・年齢・日数計算画面。タブで3つのモードを切り替える。
/// 1. 〇日後の日付を計算  2. 生年月日から年齢計算  3. 2つの日付間の日数計算
class DateCalcScreen extends ConsumerStatefulWidget {
  const DateCalcScreen({super.key});

  @override
  ConsumerState<DateCalcScreen> createState() => _DateCalcScreenState();
}

class _DateCalcScreenState extends ConsumerState<DateCalcScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _dateFormat = DateFormat('yyyy/MM/dd');

  static final DateTime _firstDate = DateTime(1900);
  static final DateTime _lastDate = DateTime(2100);

  // モード1: 〇日後の日付
  DateTime _baseDate = DateTime.now();
  final _daysController = TextEditingController();
  DateTime? _addDaysResult;
  String? _daysError;

  // モード2: 年齢計算
  DateTime _birthDate = DateTime(2000, 1, 1);
  int? _ageResult;

  // モード3: 2つの日付間の日数
  DateTime _dateA = DateTime.now();
  DateTime _dateB = DateTime.now();
  int? _daysBetweenResult;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _daysController.dispose();
    super.dispose();
  }

  Future<void> _pickDate({
    required DateTime initial,
    required ValueChanged<DateTime> onPicked,
  }) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: _firstDate,
      lastDate: _lastDate,
    );
    if (picked != null) onPicked(picked);
  }

  void _calculateAddDays() {
    final days = CalcUtils.parseInt(_daysController.text);
    setState(() => _daysError = days == null ? '正しい日数を入力してください' : null);
    if (days == null) {
      setState(() => _addDaysResult = null);
      return;
    }

    final result = CalcUtils.addDays(_baseDate, days);
    setState(() => _addDaysResult = result);

    InterstitialAdManager.instance.registerCalculationTap();

    ref.read(historyProvider.notifier).addItem(
      toolType: ToolType.dateCalc,
      inputSummary: '${_dateFormat.format(_baseDate)} の $days日後',
      resultSummary: _dateFormat.format(result),
      inputData: {
        'mode': 'addDays',
        'baseDate': _baseDate.toIso8601String(),
        'days': days.toString(),
      },
    );
  }

  void _calculateAge() {
    final today = DateTime.now();
    final age = CalcUtils.calculateAge(_birthDate, today);
    setState(() => _ageResult = age);

    InterstitialAdManager.instance.registerCalculationTap();

    ref.read(historyProvider.notifier).addItem(
      toolType: ToolType.dateCalc,
      inputSummary: '${_dateFormat.format(_birthDate)} 生まれ',
      resultSummary: '$age歳',
      inputData: {
        'mode': 'age',
        'birthDate': _birthDate.toIso8601String(),
      },
    );
  }

  void _calculateDaysBetween() {
    final days = CalcUtils.daysBetween(_dateA, _dateB);
    setState(() => _daysBetweenResult = days);

    InterstitialAdManager.instance.registerCalculationTap();

    ref.read(historyProvider.notifier).addItem(
      toolType: ToolType.dateCalc,
      inputSummary: '${_dateFormat.format(_dateA)} 〜 ${_dateFormat.format(_dateB)}',
      resultSummary: '$days日',
      inputData: {
        'mode': 'between',
        'dateA': _dateA.toIso8601String(),
        'dateB': _dateB.toIso8601String(),
      },
    );
  }

  void _applyHistory(HistoryItem item) {
    final mode = item.inputData['mode'] as String?;
    switch (mode) {
      case 'addDays':
        setState(() {
          _tabController.index = 0;
          _baseDate = DateTime.parse(item.inputData['baseDate'] as String);
          _daysController.text = item.inputData['days']?.toString() ?? '';
          _addDaysResult = null;
          _daysError = null;
        });
        break;
      case 'age':
        setState(() {
          _tabController.index = 1;
          _birthDate = DateTime.parse(item.inputData['birthDate'] as String);
          _ageResult = null;
        });
        break;
      case 'between':
        setState(() {
          _tabController.index = 2;
          _dateA = DateTime.parse(item.inputData['dateA'] as String);
          _dateB = DateTime.parse(item.inputData['dateB'] as String);
          _daysBetweenResult = null;
        });
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('日付・年齢・日数計算'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '日付計算'),
            Tab(text: '年齢計算'),
            Tab(text: '日数計算'),
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
                  _buildAddDaysTab(),
                  _buildAgeTab(),
                  _buildBetweenTab(),
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
      toolType: ToolType.dateCalc,
      onSelect: _applyHistory,
      headerPadding: const EdgeInsets.only(top: 16),
    );
  }

  Widget _buildDateField(String label, DateTime value, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          suffixIcon: const Icon(Icons.calendar_today),
        ),
        child: Text(_dateFormat.format(value)),
      ),
    );
  }

  Widget _buildAddDaysTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildDateField(
          '基準日',
          _baseDate,
          () => _pickDate(
            initial: _baseDate,
            onPicked: (d) => setState(() => _baseDate = d),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _daysController,
          keyboardType: const TextInputType.numberWithOptions(signed: true),
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^-?\d*$'))],
          decoration: InputDecoration(
            labelText: '日数(負の値で過去)',
            suffixText: '日',
            border: const OutlineInputBorder(),
            errorText: _daysError,
          ),
        ),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: _calculateAddDays,
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text('計算する'),
          ),
        ),
        const SizedBox(height: 24),
        ResultDisplay(
          label: '計算結果の日付',
          resultText: _addDaysResult == null ? '' : _dateFormat.format(_addDaysResult!),
        ),
        _buildHistory(),
      ],
    );
  }

  Widget _buildAgeTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildDateField(
          '生年月日',
          _birthDate,
          () => _pickDate(
            initial: _birthDate,
            onPicked: (d) => setState(() => _birthDate = d),
          ),
        ),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: _calculateAge,
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text('計算する'),
          ),
        ),
        const SizedBox(height: 24),
        ResultDisplay(
          label: '満年齢',
          resultText: _ageResult == null ? '' : '$_ageResult歳',
        ),
        _buildHistory(),
      ],
    );
  }

  Widget _buildBetweenTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildDateField(
          '開始日',
          _dateA,
          () => _pickDate(
            initial: _dateA,
            onPicked: (d) => setState(() => _dateA = d),
          ),
        ),
        const SizedBox(height: 16),
        _buildDateField(
          '終了日',
          _dateB,
          () => _pickDate(
            initial: _dateB,
            onPicked: (d) => setState(() => _dateB = d),
          ),
        ),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: _calculateDaysBetween,
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text('計算する'),
          ),
        ),
        const SizedBox(height: 24),
        ResultDisplay(
          label: '日数の差',
          resultText: _daysBetweenResult == null ? '' : '$_daysBetweenResult日',
        ),
        _buildHistory(),
      ],
    );
  }
}
