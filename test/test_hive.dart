import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:checkin_qr/storage/hive_setup.dart';

class TestHive {
  final Directory dir;

  TestHive._(this.dir);

  static Future<TestHive> init() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final dir = await Directory.systemTemp.createTemp('checkin_qr_hive_');
    Hive.init(dir.path);
    await Hive.openBox(HiveSetup.eventsBoxName);
    await Hive.openBox(HiveSetup.checkInsBoxName);
    await Hive.openBox(HiveSetup.settingsBoxName);
    return TestHive._(dir);
  }

  Future<void> dispose() async {
    await Hive.close();
    if (dir.existsSync()) {
      await dir.delete(recursive: true);
    }
  }
}
