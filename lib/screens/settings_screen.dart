import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/history_provider.dart';
import '../providers/settings_provider.dart';
import '../utils/calc_utils.dart';

/// アプリのバージョン表示。パッケージ肥大化を避けるため
/// pubspec.yaml の version と手動で同期させている。
/// ずれると test/app_version_test.dart が失敗する。
const String appVersion = '1.1.2';

/// 設定画面。ダークモード切り替え、単位変換のデフォルト単位、
/// 履歴の全削除、バージョン表示を行う。
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _confirmClearHistory(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('履歴を削除'),
        content: const Text('すべての計算履歴を削除します。この操作は取り消せません。'),
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

    if (confirmed == true) {
      await ref.read(historyProvider.notifier).clearAll();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('履歴を削除しました')),
        );
      }
    }
  }

  Widget _buildUnitDropdown({
    required BuildContext context,
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return ListTile(
      title: Text(label),
      trailing: DropdownButton<String>(
        value: value,
        items: items
            .map((unit) => DropdownMenuItem(value: unit, child: Text(unit)))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final settingsNotifier = ref.read(settingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('設定')),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('ダークモード'),
            secondary: const Icon(Icons.dark_mode),
            value: settings.isDarkMode,
            onChanged: settingsNotifier.setDarkMode,
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('単位変換のデフォルト単位', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
          _buildUnitDropdown(
            context: context,
            label: '長さ',
            value: settings.defaultLengthUnit,
            items: CalcUtils.unitsByCategory[UnitCategory.length]!,
            onChanged: (unit) {
              if (unit != null) settingsNotifier.setDefaultLengthUnit(unit);
            },
          ),
          _buildUnitDropdown(
            context: context,
            label: '重量',
            value: settings.defaultWeightUnit,
            items: CalcUtils.unitsByCategory[UnitCategory.weight]!,
            onChanged: (unit) {
              if (unit != null) settingsNotifier.setDefaultWeightUnit(unit);
            },
          ),
          _buildUnitDropdown(
            context: context,
            label: '温度',
            value: settings.defaultTempUnit,
            items: CalcUtils.unitsByCategory[UnitCategory.temperature]!,
            onChanged: (unit) {
              if (unit != null) settingsNotifier.setDefaultTempUnit(unit);
            },
          ),
          _buildUnitDropdown(
            context: context,
            label: '体積',
            value: settings.defaultVolumeUnit,
            items: CalcUtils.unitsByCategory[UnitCategory.volume]!,
            onChanged: (unit) {
              if (unit != null) settingsNotifier.setDefaultVolumeUnit(unit);
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.delete_outline),
            title: const Text('履歴を全て削除'),
            onTap: () => _confirmClearHistory(context, ref),
          ),
          const Divider(),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('アプリバージョン'),
            trailing: Text(appVersion),
          ),
        ],
      ),
    );
  }
}
