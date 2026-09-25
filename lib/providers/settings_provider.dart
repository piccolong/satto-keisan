import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _keyDarkMode = 'settings_dark_mode';
const String _keyDefaultLengthUnit = 'settings_default_length_unit';
const String _keyDefaultWeightUnit = 'settings_default_weight_unit';
const String _keyDefaultTempUnit = 'settings_default_temp_unit';
const String _keyDefaultVolumeUnit = 'settings_default_volume_unit';

/// アプリ全体の設定状態。
class SettingsState {
  const SettingsState({
    this.isDarkMode = false,
    this.defaultLengthUnit = 'cm',
    this.defaultWeightUnit = 'kg',
    this.defaultTempUnit = '°C',
    this.defaultVolumeUnit = 'L',
  });

  final bool isDarkMode;
  final String defaultLengthUnit;
  final String defaultWeightUnit;
  final String defaultTempUnit;
  final String defaultVolumeUnit;

  ThemeMode get themeMode => isDarkMode ? ThemeMode.dark : ThemeMode.light;

  SettingsState copyWith({
    bool? isDarkMode,
    String? defaultLengthUnit,
    String? defaultWeightUnit,
    String? defaultTempUnit,
    String? defaultVolumeUnit,
  }) {
    return SettingsState(
      isDarkMode: isDarkMode ?? this.isDarkMode,
      defaultLengthUnit: defaultLengthUnit ?? this.defaultLengthUnit,
      defaultWeightUnit: defaultWeightUnit ?? this.defaultWeightUnit,
      defaultTempUnit: defaultTempUnit ?? this.defaultTempUnit,
      defaultVolumeUnit: defaultVolumeUnit ?? this.defaultVolumeUnit,
    );
  }
}

/// 設定の読み込み・保存を行う StateNotifier。
class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier() : super(const SettingsState()) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = SettingsState(
      isDarkMode: prefs.getBool(_keyDarkMode) ?? false,
      defaultLengthUnit: prefs.getString(_keyDefaultLengthUnit) ?? 'cm',
      defaultWeightUnit: prefs.getString(_keyDefaultWeightUnit) ?? 'kg',
      defaultTempUnit: prefs.getString(_keyDefaultTempUnit) ?? '°C',
      defaultVolumeUnit: prefs.getString(_keyDefaultVolumeUnit) ?? 'L',
    );
  }

  Future<void> setDarkMode(bool value) async {
    state = state.copyWith(isDarkMode: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyDarkMode, value);
  }

  Future<void> setDefaultLengthUnit(String unit) async {
    state = state.copyWith(defaultLengthUnit: unit);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyDefaultLengthUnit, unit);
  }

  Future<void> setDefaultWeightUnit(String unit) async {
    state = state.copyWith(defaultWeightUnit: unit);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyDefaultWeightUnit, unit);
  }

  Future<void> setDefaultTempUnit(String unit) async {
    state = state.copyWith(defaultTempUnit: unit);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyDefaultTempUnit, unit);
  }

  Future<void> setDefaultVolumeUnit(String unit) async {
    state = state.copyWith(defaultVolumeUnit: unit);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyDefaultVolumeUnit, unit);
  }
}

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier();
});
