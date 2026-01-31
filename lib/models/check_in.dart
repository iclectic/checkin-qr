class CheckIn {
  final String id;
  final String eventId;
  final DateTime timestamp;
  final String? attendeeName;
  final String? attendeeEmail;
  final String? attendeeCompany;
  final String method;

  const CheckIn({
    required this.id,
    required this.eventId,
    required this.timestamp,
    required this.method,
    this.attendeeName,
    this.attendeeEmail,
    this.attendeeCompany,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'eventId': eventId,
      'timestamp': timestamp.toIso8601String(),
      'attendeeName': attendeeName,
      'attendeeEmail': attendeeEmail,
      'attendeeCompany': attendeeCompany,
      'method': method,
    };
  }

  static CheckIn fromMap(Map<dynamic, dynamic> map) {
    return CheckIn(
      id: map['id'] as String,
      eventId: map['eventId'] as String,
      timestamp: DateTime.parse(map['timestamp'] as String),
      attendeeName: map['attendeeName'] as String?,
      attendeeEmail: map['attendeeEmail'] as String?,
      attendeeCompany: map['attendeeCompany'] as String?,
      method: map['method'] as String,
    );
  }
}
