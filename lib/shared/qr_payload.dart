import '../models/event.dart';

class QrPayloadException implements Exception {
  final String message;

  QrPayloadException(this.message);

  @override
  String toString() => message;
}

class QrPayload {
  final int version;
  final String type;
  final String eventId;
  final String eventCode;

  const QrPayload({
    required this.version,
    required this.type,
    required this.eventId,
    required this.eventCode,
  });

  static QrPayload parse(String raw) {
    final parts = raw.split('|');
    if (parts.length != 5) {
      throw QrPayloadException('Invalid QR code format.');
    }

    final magic = parts[0];
    if (magic != 'MCQ') {
      throw QrPayloadException('This QR code is not for this app.');
    }

    final versionStr = parts[1];
    final version = int.tryParse(versionStr);
    if (version == null) {
      throw QrPayloadException('Invalid QR code version.');
    }

    final type = parts[2];
    if (type != 'EVENT') {
      throw QrPayloadException('Unsupported QR code type.');
    }

    final eventId = parts[3];
    final eventCode = parts[4];

    if (eventId.isEmpty || eventCode.isEmpty) {
      throw QrPayloadException('Invalid QR code payload.');
    }

    return QrPayload(version: version, type: type, eventId: eventId, eventCode: eventCode);
  }

  void validateAgainstEvent(Event event) {
    if (event.id != eventId) {
      throw QrPayloadException('This QR code is for a different event.');
    }
    if (event.eventCode != eventCode) {
      throw QrPayloadException('This QR code does not match the event code.');
    }
  }
}
