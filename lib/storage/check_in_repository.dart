import 'package:hive/hive.dart';

import '../models/check_in.dart';
import 'hive_setup.dart';

class CheckInRepository {
  Box get _box => Hive.box(HiveSetup.checkInsBoxName);

  Future<void> add(CheckIn checkIn) async {
    await _box.put(checkIn.id, checkIn.toMap());
  }

  List<CheckIn> listByEvent(String eventId) {
    return _box.values
        .map((e) => Map<dynamic, dynamic>.from(e as Map))
        .map(CheckIn.fromMap)
        .where((c) => c.eventId == eventId)
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  int countByEvent(String eventId) {
    return _box.values
        .map((e) => Map<dynamic, dynamic>.from(e as Map))
        .where((m) => m['eventId'] == eventId)
        .length;
  }

  Future<void> delete(String id) async {
    await _box.delete(id);
  }

  Future<void> deleteAllForEvent(String eventId) async {
    final ids = <dynamic>[];
    _box.toMap().forEach((key, value) {
      final map = Map<dynamic, dynamic>.from(value as Map);
      if (map['eventId'] == eventId) ids.add(key);
    });
    await _box.deleteAll(ids);
  }
}
