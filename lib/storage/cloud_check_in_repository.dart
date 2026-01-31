import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/check_in.dart';
import '../models/event.dart';
import '../shared/app_config.dart';

class CloudSyncException implements Exception {
  final String message;

  CloudSyncException(this.message);

  @override
  String toString() => message;
}

class CloudCheckInRepository {
  SupabaseClient get _client {
    if (!AppConfig.supabaseConfigured) {
      throw CloudSyncException(
        'Cloud sync is not configured. Set SUPABASE_URL and SUPABASE_ANON_KEY.',
      );
    }
    return Supabase.instance.client;
  }

  Future<List<CheckIn>> listByEvent(Event event) async {
    try {
      final response = await _client
          .from('check_ins')
          .select()
          .eq('event_id', event.id)
          .eq('event_code', event.eventCode)
          .order('timestamp', ascending: false);

      if (response is! List) {
        return [];
      }

      return response
          .map((row) => _fromRow(row as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw CloudSyncException(e.message);
    }
  }

  Future<int> upsertAll(Event event, List<CheckIn> checkIns) async {
    if (checkIns.isEmpty) return 0;

    final payload = checkIns.map((c) => _toRow(c, event)).toList();

    try {
      await _client.from('check_ins').upsert(payload, onConflict: 'id');
      return payload.length;
    } on PostgrestException catch (e) {
      throw CloudSyncException(e.message);
    }
  }

  CheckIn _fromRow(Map<String, dynamic> row) {
    return CheckIn(
      id: row['id'] as String,
      eventId: row['event_id'] as String,
      timestamp: DateTime.parse(row['timestamp'] as String),
      attendeeName: row['attendee_name'] as String?,
      attendeeEmail: row['attendee_email'] as String?,
      attendeeCompany: row['attendee_company'] as String?,
      method: (row['method'] as String?) ?? 'self',
    );
  }

  Map<String, dynamic> _toRow(CheckIn checkIn, Event event) {
    return {
      'id': checkIn.id,
      'event_id': event.id,
      'event_code': event.eventCode,
      'timestamp': checkIn.timestamp.toIso8601String(),
      'attendee_name': checkIn.attendeeName,
      'attendee_email': checkIn.attendeeEmail,
      'attendee_company': checkIn.attendeeCompany,
      'method': checkIn.method,
    };
  }
}
