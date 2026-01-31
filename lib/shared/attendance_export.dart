import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/check_in.dart';
import '../models/event.dart';
import '../shared/date_format.dart';
import '../storage/app_settings.dart';

const bool _isFlutterTest = bool.fromEnvironment('FLUTTER_TEST');

class AttendanceCsvExporter {
  static Future<void> share(Event event, List<CheckIn> checkIns) async {
    final csv = buildCsv(event, checkIns);
    final file = await _writeCsvToTemp(event, csv);
    if (_isFlutterTest) return;
    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Attendance export for ${event.title}',
    );
  }

  static String buildCsv(Event event, List<CheckIn> checkIns) {
    final includeExtras = AppSettings.exportFormatOption == ExportFormatOption.csvWithExtras;
    final rows = <List<String>>[
      [
        'Event title',
        'Event date and time',
        'Attendee name',
        if (includeExtras) 'Attendee email',
        if (includeExtras) 'Attendee company',
        'Check-in time',
        'Method',
      ],
    ];

    final sorted = List<CheckIn>.from(checkIns)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    for (final checkIn in sorted) {
      rows.add([
        event.title,
        formatDateTime(event.dateTime),
        checkIn.attendeeName ?? '',
        if (includeExtras) checkIn.attendeeEmail ?? '',
        if (includeExtras) checkIn.attendeeCompany ?? '',
        formatDateTime(checkIn.timestamp),
        checkIn.method,
      ]);
    }

    return rows.map(_encodeRow).join('\n');
  }

  static Future<File> _writeCsvToTemp(Event event, String csv) async {
    final dir = await getTemporaryDirectory();
    final filename = _buildFileName(event);
    final file = File('${dir.path}/$filename');
    return file.writeAsString(csv);
  }

  static String _buildFileName(Event event) {
    final date = formatDateForFilename(event.dateTime);
    final safeTitle = _sanitizeFilePart(event.title);
    return 'meetup-checkins_${safeTitle}_$date.csv';
  }

  static String _sanitizeFilePart(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return 'event';

    final withUnderscores = trimmed.replaceAll(RegExp(r'\s+'), '_');
    final cleaned = withUnderscores.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '');
    final collapsed = cleaned.replaceAll(RegExp(r'_+'), '_');
    return collapsed.isEmpty ? 'event' : collapsed;
  }

  static String _encodeRow(List<String> columns) {
    return columns.map(_escape).join(',');
  }

  static String _escape(String value) {
    final escaped = value.replaceAll('"', '""');
    final needsQuotes = escaped.contains(',') ||
        escaped.contains('"') ||
        escaped.contains('\n') ||
        escaped.contains('\r');
    return needsQuotes ? '"$escaped"' : escaped;
  }

  // Date formatting handled by shared helpers.
}
