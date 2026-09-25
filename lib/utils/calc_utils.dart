import 'dart:math' as math;

/// 割り勘計算における端数処理方法。
enum RoundingMode {
  ceil('切り上げ'),
  floor('切り捨て'),
  round('四捨五入');

  const RoundingMode(this.label);
  final String label;
}

/// 単位変換のカテゴリ。
enum UnitCategory {
  length('長さ'),
  weight('重量'),
  temperature('温度'),
  volume('体積');

  const UnitCategory(this.label);
  final String label;
}

/// 各種計算ロジックをまとめたユーティリティクラス。
/// すべて純粋関数として実装し、UIから独立してテスト可能にしている。
class CalcUtils {
  CalcUtils._();

  // ─────────────────────────── 割り勘計算 ───────────────────────────

  /// 合計金額 [total] を [people] 人で割り、[mode] に従って端数処理する。
  /// 1人あたりの金額を返す。
  static int calculateWarikan({
    required int total,
    required int people,
    required RoundingMode mode,
  }) {
    if (people <= 0) return 0;
    final raw = total / people;
    switch (mode) {
      case RoundingMode.ceil:
        return raw.ceil();
      case RoundingMode.floor:
        return raw.floor();
      case RoundingMode.round:
        return raw.round();
    }
  }

  // ─────────────────────────── 日付計算 ───────────────────────────

  /// 基準日 [base] の [days] 日後(負の値で前)の日付を返す。
  static DateTime addDays(DateTime base, int days) {
    return DateTime(base.year, base.month, base.day).add(Duration(days: days));
  }

  /// 生年月日 [birthDate] から [today] 時点の満年齢を計算する。
  static int calculateAge(DateTime birthDate, DateTime today) {
    int age = today.year - birthDate.year;
    final hasHadBirthdayThisYear = (today.month > birthDate.month) ||
        (today.month == birthDate.month && today.day >= birthDate.day);
    if (!hasHadBirthdayThisYear) {
      age--;
    }
    return math.max(age, 0);
  }

  /// 2つの日付間の日数(絶対値)を計算する。
  static int daysBetween(DateTime a, DateTime b) {
    final dateA = DateTime(a.year, a.month, a.day);
    final dateB = DateTime(b.year, b.month, b.day);
    return dateB.difference(dateA).inDays.abs();
  }

  // ─────────────────────────── 単位変換 ───────────────────────────

  /// 各カテゴリで選択可能な単位一覧。
  static const Map<UnitCategory, List<String>> unitsByCategory = {
    UnitCategory.length: ['mm', 'cm', 'm', 'km', 'inch', 'feet', 'mile'],
    UnitCategory.weight: ['mg', 'g', 'kg', 't', 'oz', 'lb'],
    UnitCategory.temperature: ['°C', '°F', 'K'],
    UnitCategory.volume: ['mL', 'L', 'm3', 'gal(US)', 'cup'],
  };

  /// 長さ単位からメートルへの換算係数。
  static const Map<String, double> _lengthToMeter = {
    'mm': 0.001,
    'cm': 0.01,
    'm': 1.0,
    'km': 1000.0,
    'inch': 0.0254,
    'feet': 0.3048,
    'mile': 1609.344,
  };

  /// 重量単位からグラムへの換算係数。
  static const Map<String, double> _weightToGram = {
    'mg': 0.001,
    'g': 1.0,
    'kg': 1000.0,
    't': 1000000.0,
    'oz': 28.349523125,
    'lb': 453.59237,
  };

  /// 体積単位からリットルへの換算係数。
  static const Map<String, double> _volumeToLiter = {
    'mL': 0.001,
    'L': 1.0,
    'm3': 1000.0,
    'gal(US)': 3.785411784,
    'cup': 0.2365882365,
  };

  /// [category] に従い、[value] を [from] 単位から [to] 単位へ変換する。
  static double convertUnit({
    required UnitCategory category,
    required String from,
    required String to,
    required double value,
  }) {
    switch (category) {
      case UnitCategory.length:
        return _convertLinear(_lengthToMeter, from, to, value);
      case UnitCategory.weight:
        return _convertLinear(_weightToGram, from, to, value);
      case UnitCategory.volume:
        return _convertLinear(_volumeToLiter, from, to, value);
      case UnitCategory.temperature:
        return _convertTemperature(from, to, value);
    }
  }

  static double _convertLinear(
    Map<String, double> toBaseFactor,
    String from,
    String to,
    double value,
  ) {
    final fromFactor = toBaseFactor[from];
    final toFactor = toBaseFactor[to];
    if (fromFactor == null || toFactor == null) return value;
    final baseValue = value * fromFactor;
    return baseValue / toFactor;
  }

  static double _convertTemperature(String from, String to, double value) {
    if (from == to) return value;
    // まず摂氏に変換
    double celsius;
    switch (from) {
      case '°F':
        celsius = (value - 32) * 5 / 9;
        break;
      case 'K':
        celsius = value - 273.15;
        break;
      case '°C':
      default:
        celsius = value;
    }
    // 摂氏から変換先へ
    switch (to) {
      case '°F':
        return celsius * 9 / 5 + 32;
      case 'K':
        return celsius + 273.15;
      case '°C':
      default:
        return celsius;
    }
  }

  // ─────────────────────────── 消費税計算 ───────────────────────────

  /// 税抜き金額 [amount] に税率 [taxRatePercent](%) を適用した税込み金額。
  static double taxExclusiveToInclusive(double amount, double taxRatePercent) {
    return amount * (1 + taxRatePercent / 100);
  }

  /// 税込み金額 [amount] から税率 [taxRatePercent](%) を差し引いた税抜き金額。
  static double taxInclusiveToExclusive(double amount, double taxRatePercent) {
    return amount / (1 + taxRatePercent / 100);
  }

  // ─────────────────────────── パーセント計算 ───────────────────────────

  /// 元価格 [original] から [discountPercent](%) 割引した後の価格。
  static double discountedPrice(double original, double discountPercent) {
    return original * (1 - discountPercent / 100);
  }

  /// [oldValue] から [newValue] への変化率(%)を計算する。
  /// oldValue が 0 の場合は 0 を返す(ゼロ除算回避)。
  static double changeRate(double oldValue, double newValue) {
    if (oldValue == 0) return 0;
    return (newValue - oldValue) / oldValue * 100;
  }

  // ─────────────────────────── 入力バリデーション ───────────────────────────

  /// 文字列を数値としてパースする。空欄・不正値は null を返す。
  static double? parseDouble(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return null;
    return double.tryParse(trimmed);
  }

  /// 文字列を整数としてパースする。空欄・不正値は null を返す。
  static int? parseInt(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return null;
    return int.tryParse(trimmed);
  }
}
