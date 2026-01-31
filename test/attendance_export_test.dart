import 'package:flutter_test/flutter_test.dart';

import 'package:checkin_qr/models/check_in.dart';
import 'package:checkin_qr/models/event.dart';
import 'package:checkin_qr/shared/attendance_export.dart';
import 'package:checkin_qr/storage/app_settings.dart';

import 'test_hive.dart';

void main() {
  late TestHive hive;

  setUp(() async {
    hive = await TestHive.init();
  });

  tearDown(() async {
    await hive.dispose();
  });

  test('builds standard CSV with escaped values', () async {
    await AppSettings.setDateFormatOption(DateFormatOption.ymd);
    await AppSettings.setExportFormatOption(ExportFormatOption.csv);

    final event = Event(
      id: 'event-1',
      title: 'Meetup, "Alpha"',
      dateTime: DateTime(2025, 1, 2, 9, 5),
      location: 'Room 1',
      eventCode: 'ABCDE',
      createdAt: DateTime(2025, 1, 1),
    );

    final checkIns = [
      CheckIn(
        id: 'c1',
        eventId: event.id,
        timestamp: DateTime(2025, 1, 2, 10, 0),
        attendeeName: 'Ada Lovelace',
        method: 'scan',
      ),
    ];

    final csv = AttendanceCsvExporter.buildCsv(event, checkIns);
    final lines = csv.split('\n');

    expect(
      lines.first,
      'Event title,Event date and time,Attendee name,Check-in time,Method',
    );
    expect(lines.length, 2);
    expect(
      lines[1].startsWith('"Meetup, ""Alpha"""'),
      isTrue,
    );
    expect(lines[1].contains('2025-01-02 09:05'), isTrue);
    expect(lines[1].contains('2025-01-02 10:00'), isTrue);
  });

  test('builds CSV with extra fields when enabled', () async {
    await AppSettings.setDateFormatOption(DateFormatOption.mdy);
    await AppSettings.setExportFormatOption(ExportFormatOption.csvWithExtras);

    final event = Event(
      id: 'event-2',
      title: 'Workshop',
      dateTime: DateTime(2025, 3, 4, 14, 30),
      location: 'Hall',
      eventCode: 'QWERT',
      createdAt: DateTime(2025, 1, 1),
    );

    final checkIns = [
      CheckIn(
        id: 'c2',
        eventId: event.id,
        timestamp: DateTime(2025, 3, 4, 15, 0),
        attendeeName: 'Grace Hopper',
        attendeeEmail: 'grace@example.com',
        attendeeCompany: 'Navy',
        method: 'manual',
      ),
    ];

    final csv = AttendanceCsvExporter.buildCsv(event, checkIns);
    final lines = csv.split('\n');

    expect(
      lines.first,
      'Event title,Event date and time,Attendee name,Attendee email,Attendee company,Check-in time,Method',
    );
    expect(lines[1].contains('03/04/2025 14:30'), isTrue);
    expect(lines[1].contains('03/04/2025 15:00'), isTrue);
    expect(lines[1].contains('grace@example.com'), isTrue);
    expect(lines[1].contains('Navy'), isTrue);
  });
}
