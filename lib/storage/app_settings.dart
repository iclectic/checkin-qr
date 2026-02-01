import 'package:hive/hive.dart';

import 'hive_setup.dart';

enum DuplicateScanBehavior {
  block,
  warn,
  allow,
}

enum DateFormatOption {
  ymd,
  mdy,
}

enum ExportFormatOption {
  csv,
  csvWithExtras,
}

enum ThemeModeOption {
  system,
  light,
  dark,
}

class AppSettings {
  static const _keyOnboardingSeen = 'onboarding_seen';
  static const _keyEnableNameCapture = 'enable_name_capture';
  static const _keyDuplicateScanBehavior = 'duplicate_scan_behavior';
  static const _keyDateFormat = 'date_format';
  static const _keyExportFormat = 'export_format';
  static const _keyCloudSyncEnabled = 'cloud_sync_enabled';
  static const _keyThemeMode = 'theme_mode';

  static Box get _box => Hive.box(HiveSetup.settingsBoxName);

  static bool get onboardingSeen =>
      _box.get(_keyOnboardingSeen, defaultValue: false) as bool;

  static Future<void> setOnboardingSeen(bool value) async {
    await _box.put(_keyOnboardingSeen, value);
  }

  static bool get enableNameCapture =>
      _box.get(_keyEnableNameCapture, defaultValue: true) as bool;

  static Future<void> setEnableNameCapture(bool value) async {
    await _box.put(_keyEnableNameCapture, value);
  }

  static DuplicateScanBehavior get duplicateScanBehavior {
    final raw =
        _box.get(_keyDuplicateScanBehavior, defaultValue: 'block') as String;
    return DuplicateScanBehavior.values
        .firstWhere((e) => e.name == raw, orElse: () => DuplicateScanBehavior.block);
  }

  static Future<void> setDuplicateScanBehavior(
    DuplicateScanBehavior value,
  ) async {
    await _box.put(_keyDuplicateScanBehavior, value.name);
  }

  static DateFormatOption get dateFormatOption {
    final raw = _box.get(_keyDateFormat, defaultValue: 'ymd') as String;
    return DateFormatOption.values
        .firstWhere((e) => e.name == raw, orElse: () => DateFormatOption.ymd);
  }

  static Future<void> setDateFormatOption(DateFormatOption value) async {
    await _box.put(_keyDateFormat, value.name);
  }

  static ExportFormatOption get exportFormatOption {
    final raw = _box.get(_keyExportFormat, defaultValue: 'csv') as String;
    return ExportFormatOption.values
        .firstWhere((e) => e.name == raw, orElse: () => ExportFormatOption.csv);
  }

  static Future<void> setExportFormatOption(ExportFormatOption value) async {
    await _box.put(_keyExportFormat, value.name);
  }

  static bool get cloudSyncEnabled =>
      _box.get(_keyCloudSyncEnabled, defaultValue: false) as bool;

  static Future<void> setCloudSyncEnabled(bool value) async {
    await _box.put(_keyCloudSyncEnabled, value);
  }

  static ThemeModeOption get themeModeOption {
    final raw = _box.get(_keyThemeMode, defaultValue: 'system') as String;
    return ThemeModeOption.values
        .firstWhere((e) => e.name == raw, orElse: () => ThemeModeOption.system);
  }

  static Future<void> setThemeModeOption(ThemeModeOption value) async {
    await _box.put(_keyThemeMode, value.name);
  }
}
