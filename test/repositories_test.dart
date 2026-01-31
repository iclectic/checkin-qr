import 'package:flutter_test/flutter_test.dart';

import 'package:checkin_qr/models/check_in.dart';
import 'package:checkin_qr/models/event.dart';
import 'package:checkin_qr/storage/check_in_repository.dart';
import 'package:checkin_qr/storage/event_repository.dart';

import 'test_hive.dart';

void main() {
  late TestHive hive;

  setUp(() async {
    hive = await TestHive.init();
  });

  tearDown(() async {
    await hive.dispose();
  });

  test('event repository CRUD', () async {
    final repo = EventRepository();
    final event = Event(
      id: 'event-1',
      title: 'Event One',
      dateTime: DateTime(2025, 1, 1, 10, 0),
      location: 'Room A',
      eventCode: 'ABCDE',
      createdAt: DateTime(2024, 12, 1),
    );

    await repo.create(event);
    expect(repo.exists(event.id), isTrue);
    expect(repo.getById(event.id)?.title, 'Event One');

    final updated = Event(
      id: event.id,
      title: 'Event One Updated',
      dateTime: event.dateTime,
      location: event.location,
      eventCode: event.eventCode,
      createdAt: event.createdAt,
    );
    await repo.update(updated);
    expect(repo.getById(event.id)?.title, 'Event One Updated');

    await repo.deleteEvent(event.id);
    expect(repo.exists(event.id), isFalse);
  });

  test('check-in repository lists and counts by event', () async {
    final repo = CheckInRepository();
    final eventId = 'event-1';

    final first = CheckIn(
      id: 'c1',
      eventId: eventId,
      timestamp: DateTime(2025, 1, 1, 9, 0),
      attendeeName: 'First',
      method: 'scan',
    );
    final second = CheckIn(
      id: 'c2',
      eventId: eventId,
      timestamp: DateTime(2025, 1, 1, 10, 0),
      attendeeName: 'Second',
      method: 'manual',
    );

    await repo.add(first);
    await repo.add(second);

    expect(repo.countByEvent(eventId), 2);

    final list = repo.listByEvent(eventId);
    expect(list.length, 2);
    expect(list.first.id, 'c2'); // newest first
    expect(list.last.id, 'c1');

    await repo.deleteAllForEvent(eventId);
    expect(repo.countByEvent(eventId), 0);
  });
}
