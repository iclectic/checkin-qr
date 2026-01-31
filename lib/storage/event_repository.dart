import 'package:hive/hive.dart';
import 'hive_setup.dart';

import '../models/event.dart';

class EventRepository {
     Box get _box => Hive.box(HiveSetup.eventsBoxName);

     List<Map<dynamic, dynamic>> getAllRaw() {
        return _box.values
            .map((e) => Map<dynamic, dynamic>.from(e as Map))
            .toList();
     }

     List<Event> getAll() {
        return getAllRaw().map(Event.fromMap).toList();
     }

     Future<void> saveEventMap(String id, Map<String, dynamic> eventMap) async {
        await _box.put(id, eventMap);
     }

     Future<void> create(Event event) async {
        await saveEventMap(event.id, event.toMap());
     }

     Map<dynamic, dynamic>? getEventRawById(String id) {
        final value = _box.get(id);
        if (value == null) return null;
        return Map<dynamic, dynamic>.from(value as Map);
     }

     Event? getById(String id) {
        final raw = getEventRawById(id);
        if (raw == null) return null;
        return Event.fromMap(raw);
     }

     bool exists(String id) {
        return _box.containsKey(id);
     }

     Future<void> deleteEvent(String id) async {
        await _box.delete(id);
     }

     Future<void> update(Event event) async {
        await saveEventMap(event.id, event.toMap());
     }
}
