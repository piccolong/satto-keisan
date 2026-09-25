/// 各計算ツールの識別子。
enum ToolType {
  warikan,
  dateCalc,
  unitConvert,
  taxCalc,
  percentCalc;

  String get label {
    switch (this) {
      case ToolType.warikan:
        return '割り勘計算';
      case ToolType.dateCalc:
        return '日数・日付計算';
      case ToolType.unitConvert:
        return '単位変換';
      case ToolType.taxCalc:
        return '消費税計算';
      case ToolType.percentCalc:
        return 'パーセント計算';
    }
  }
}

/// 計算履歴の1件を表すモデル。
///
/// [inputData] には各画面が入力値を復元するために必要な生データを
/// 保持する(例: `{"total": "3000", "people": "4"}`)。
class HistoryItem {
  const HistoryItem({
    required this.id,
    required this.toolType,
    required this.inputSummary,
    required this.resultSummary,
    required this.timestamp,
    this.inputData = const {},
  });

  final String id;
  final ToolType toolType;
  final String inputSummary;
  final String resultSummary;
  final DateTime timestamp;
  final Map<String, dynamic> inputData;

  Map<String, dynamic> toJson() => {
        'id': id,
        'toolType': toolType.name,
        'inputSummary': inputSummary,
        'resultSummary': resultSummary,
        'timestamp': timestamp.toIso8601String(),
        'inputData': inputData,
      };

  factory HistoryItem.fromJson(Map<String, dynamic> json) {
    return HistoryItem(
      id: json['id'] as String,
      toolType: ToolType.values.firstWhere(
        (e) => e.name == json['toolType'],
        orElse: () => ToolType.warikan,
      ),
      inputSummary: json['inputSummary'] as String,
      resultSummary: json['resultSummary'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      inputData: Map<String, dynamic>.from(json['inputData'] as Map? ?? {}),
    );
  }
}
