import 'package:hive_flutter/hive_flutter.dart';

class HiveSetup {
    static const String eventsBoxName = 'events';
    static const String checkInsBoxName = 'check_ins';
    static const String settingsBoxName = 'settings';

    static Future<void> init() async {
        await Hive.initFlutter();
        await Hive.openBox(eventsBoxName);
        await Hive.openBox(checkInsBoxName);
        await Hive.openBox(settingsBoxName);
    }
}
