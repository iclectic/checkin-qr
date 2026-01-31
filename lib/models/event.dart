class Event {
    final String id;
    final String title;
    final DateTime dateTime;
    final String location;
    final String eventCode;
    final DateTime createdAt;

    const Event ({
        required this.id,
        required this.title,
        required this.dateTime,
        required this.location,
        required this.eventCode,
        required this.createdAt,
    });

    Map<String, dynamic> toMap() {
        return {
            'id': id,
            'title': title,
            'dateTime': dateTime.toIso8601String(),
            'location': location,
            'eventCode': eventCode,
            'createdAt': createdAt.toIso8601String(),
        };
    }

    static Event fromMap(Map<dynamic, dynamic> map) {
        return Event(
            id: map['id'] as String,
            title: map['title'] as String,
            dateTime: DateTime.parse(map['dateTime'] as String),
            location: map['location'] as String,
            eventCode: map['eventCode'] as String,
            createdAt: map['createdAt'] == null
                ? DateTime.now()
                : DateTime.parse(map['createdAt'] as String),
        );
    }

    String qrPayload() {
        // Stable payload format for later scanning and validation
        // MCQ|1|EVENT|<eventId>|<eventCode>
        return 'MCQ|1|EVENT|$id|$eventCode';
    }
}