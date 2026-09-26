import 'package:flutter/material.dart';

import '../widgets/ad_banner_widget.dart';
import '../widgets/calculator_card.dart';
import 'date_calc_screen.dart';
import 'percent_calc_screen.dart';
import 'settings_screen.dart';
import 'tax_calc_screen.dart';
import 'unit_convert_screen.dart';
import 'warikan_screen.dart';

class _ToolEntry {
  const _ToolEntry(this.icon, this.label, this.builder);
  final IconData icon;
  final String label;
  final WidgetBuilder builder;
}

final List<_ToolEntry> _tools = [
  _ToolEntry(Icons.groups, '割り勘計算', (_) => const WarikanScreen()),
  _ToolEntry(Icons.event, '日付・年齢・日数計算', (_) => const DateCalcScreen()),
  _ToolEntry(Icons.swap_horiz, '単位変換', (_) => const UnitConvertScreen()),
  _ToolEntry(Icons.receipt_long, '消費税計算', (_) => const TaxCalcScreen()),
  _ToolEntry(Icons.percent, 'パーセント計算', (_) => const PercentCalcScreen()),
];

/// ホーム画面。5つのツールへの入口をグリッド表示する。
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('サッと計算'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: '設定',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.1,
                ),
                itemCount: _tools.length,
                itemBuilder: (context, index) {
                  final tool = _tools[index];
                  return CalculatorCard(
                    icon: tool.icon,
                    label: tool.label,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: tool.builder),
                      );
                    },
                  );
                },
              ),
            ),
            const AdBannerWidget(),
          ],
        ),
      ),
    );
  }
}
