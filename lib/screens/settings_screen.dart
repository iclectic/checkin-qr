import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../shared/app_config.dart';
import '../shared/snackbars.dart';
import '../storage/app_settings.dart';
import '../storage/hive_setup.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ValueListenableBuilder(
        valueListenable: Hive.box(HiveSetup.settingsBoxName).listenable(),
        builder: (context, Box _, __) {
          final enableNameCapture = AppSettings.enableNameCapture;
          final duplicateBehavior = AppSettings.duplicateScanBehavior;
          final dateFormat = AppSettings.dateFormatOption;
          final exportFormat = AppSettings.exportFormatOption;
          final cloudEnabled = AppSettings.cloudSyncEnabled;
          final cloudConfigured = AppConfig.supabaseConfigured;
          final selfCheckInConfigured = AppConfig.selfCheckInConfigured;
          final cloudActive = cloudEnabled && cloudConfigured;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('Check-in', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Enable name capture'),
                subtitle: const Text('Prompt for attendee names after scanning.'),
                value: enableNameCapture,
                onChanged: (value) => AppSettings.setEnableNameCapture(value),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<DuplicateScanBehavior>(
                value: duplicateBehavior,
                decoration: const InputDecoration(
                  labelText: 'Duplicate scan behaviour',
                  border: OutlineInputBorder(),
                ),
                items: DuplicateScanBehavior.values
                    .map(
                      (value) => DropdownMenuItem(
                        value: value,
                        child: Text(_duplicateBehaviorLabel(value)),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value == null) return;
                  AppSettings.setDuplicateScanBehavior(value);
                },
              ),
              const SizedBox(height: 24),
              Text('Format', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              DropdownButtonFormField<DateFormatOption>(
                value: dateFormat,
                decoration: const InputDecoration(
                  labelText: 'Date format',
                  border: OutlineInputBorder(),
                ),
                items: DateFormatOption.values
                    .map(
                      (value) => DropdownMenuItem(
                        value: value,
                        child: Text(_dateFormatLabel(value)),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value == null) return;
                  AppSettings.setDateFormatOption(value);
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<ExportFormatOption>(
                value: exportFormat,
                decoration: const InputDecoration(
                  labelText: 'Export format',
                  border: OutlineInputBorder(),
                ),
                items: ExportFormatOption.values
                    .map(
                      (value) => DropdownMenuItem(
                        value: value,
                        child: Text(_exportFormatLabel(value)),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value == null) return;
                  AppSettings.setExportFormatOption(value);
                },
              ),
              const SizedBox(height: 24),
              Text('Appearance', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              DropdownButtonFormField<ThemeModeOption>(
                value: AppSettings.themeModeOption,
                decoration: const InputDecoration(
                  labelText: 'Theme',
                  border: OutlineInputBorder(),
                ),
                items: ThemeModeOption.values
                    .map(
                      (value) => DropdownMenuItem(
                        value: value,
                        child: Text(_themeModeLabel(value)),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value == null) return;
                  AppSettings.setThemeModeOption(value);
                },
              ),
              const SizedBox(height: 24),
              Text('Cloud', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Enable cloud sync'),
                subtitle: Text(
                  cloudConfigured
                      ? 'Upload and download check-ins with your Supabase backend.'
                      : 'Supabase is not configured. Set SUPABASE_URL and SUPABASE_ANON_KEY.',
                ),
                value: cloudEnabled,
                onChanged: cloudConfigured
                    ? (value) => AppSettings.setCloudSyncEnabled(value)
                    : null,
              ),
              if (!selfCheckInConfigured) ...[
                const SizedBox(height: 4),
                Text(
                  'Self check-in QR requires SELF_CHECKIN_BASE_URL to be set.',
                  style: theme.textTheme.bodyMedium,
                ),
              ] else ...[
                const SizedBox(height: 4),
                Text(
                  'Self check-in URL: ${AppConfig.selfCheckInBaseUrl}',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
              const SizedBox(height: 24),
              Text('Privacy', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(
                cloudActive
                    ? 'Cloud sync is enabled. Check-ins may be uploaded to your '
                        'Supabase project during sync. Disable cloud sync to keep '
                        'all data on this device.'
                    : 'Event details and check-ins (including attendee names and optional '
                        'email/company) are stored locally on this device using the app’s '
                        'offline database. No data is uploaded or synced.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              Text('Data', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.delete_forever),
                title: const Text('Delete all data'),
                subtitle:
                    const Text('Removes all events and check-ins from this device.'),
                onTap: () => _confirmDeleteAllData(context),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _confirmDeleteAllData(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete all data?'),
          content: const Text(
            'This will permanently remove all events and check-ins stored on this device.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete all'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    await Hive.box(HiveSetup.eventsBoxName).clear();
    await Hive.box(HiveSetup.checkInsBoxName).clear();

    if (!context.mounted) return;
    showSuccessSnackBar(context, 'All data deleted.');
  }

  String _duplicateBehaviorLabel(DuplicateScanBehavior behavior) {
    switch (behavior) {
      case DuplicateScanBehavior.block:
        return 'Block duplicates (recommended)';
      case DuplicateScanBehavior.warn:
        return 'Allow, but show a warning';
      case DuplicateScanBehavior.allow:
        return 'Allow duplicates';
    }
  }

  String _dateFormatLabel(DateFormatOption option) {
    switch (option) {
      case DateFormatOption.ymd:
        return 'YYYY-MM-DD 24h';
      case DateFormatOption.mdy:
        return 'MM/DD/YYYY 24h';
    }
  }

  String _exportFormatLabel(ExportFormatOption option) {
    switch (option) {
      case ExportFormatOption.csv:
        return 'CSV (standard)';
      case ExportFormatOption.csvWithExtras:
        return 'CSV (include email & company)';
    }
  }

  String _themeModeLabel(ThemeModeOption option) {
    switch (option) {
      case ThemeModeOption.system:
        return 'System default';
      case ThemeModeOption.light:
        return 'Light';
      case ThemeModeOption.dark:
        return 'Dark';
    }
  }
}
