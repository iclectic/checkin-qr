import 'package:flutter_test/flutter_test.dart';

import 'package:checkin_qr/models/event.dart';
import 'package:checkin_qr/shared/qr_payload.dart';

void main() {
  test('parses valid payload', () {
    const raw = 'MCQ|1|EVENT|event-123|CODE42';
    final payload = QrPayload.parse(raw);

    expect(payload.version, 1);
    expect(payload.type, 'EVENT');
    expect(payload.eventId, 'event-123');
    expect(payload.eventCode, 'CODE42');
  });

  test('rejects invalid payload formats', () {
    expect(
      () => QrPayload.parse('MCQ|1|EVENT|only-four'),
      throwsA(isA<QrPayloadException>()),
    );

    expect(
      () => QrPayload.parse('BAD|1|EVENT|event|code'),
      throwsA(isA<QrPayloadException>()),
    );

    expect(
      () => QrPayload.parse('MCQ|x|EVENT|event|code'),
      throwsA(isA<QrPayloadException>()),
    );

    expect(
      () => QrPayload.parse('MCQ|1|BAD|event|code'),
      throwsA(isA<QrPayloadException>()),
    );

    expect(
      () => QrPayload.parse('MCQ|1|EVENT||code'),
      throwsA(isA<QrPayloadException>()),
    );
  });

  test('validates against event', () {
    final event = Event(
      id: 'event-1',
      title: 'Test',
      dateTime: DateTime(2025, 1, 1),
      location: 'Anywhere',
      eventCode: 'ABCD',
      createdAt: DateTime(2024, 12, 1),
    );

    final payload = QrPayload.parse('MCQ|1|EVENT|event-1|ABCD');
    expect(() => payload.validateAgainstEvent(event), returnsNormally);

    final badEvent = Event(
      id: 'event-2',
      title: 'Test',
      dateTime: DateTime(2025, 1, 1),
      location: 'Anywhere',
      eventCode: 'WXYZ',
      createdAt: DateTime(2024, 12, 1),
    );
    expect(
      () => payload.validateAgainstEvent(badEvent),
      throwsA(isA<QrPayloadException>()),
    );
  });
}
