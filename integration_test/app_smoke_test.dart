import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:hive/hive.dart';

import 'package:checkin_qr/main.dart' as app;
import 'package:checkin_qr/storage/app_settings.dart';
import 'package:checkin_qr/storage/hive_setup.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('create event → scan → export', (tester) async {
    app.main();
    await tester.pumpAndSettle();

    if (find.text('Welcome to Meetup Check In QR').evaluate().isNotEmpty) {
      await tester.tap(find.text('Get started'));
      await tester.pumpAndSettle();
    }

    await tester.runAsync(() async {
      await Hive.box(HiveSetup.eventsBoxName).clear();
      await Hive.box(HiveSetup.checkInsBoxName).clear();
      await AppSettings.setEnableNameCapture(false);
      await AppSettings.setDuplicateScanBehavior(DuplicateScanBehavior.allow);
    });

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    Finder fieldWithLabel(String label) {
      return find.byWidgetPredicate(
        (widget) =>
            widget is TextFormField && widget.decoration?.labelText == label,
      );
    }

    await tester.enterText(fieldWithLabel('Event title'), 'Integration Event');
    await tester.enterText(fieldWithLabel('Location'), 'Main Hall');

    await tester.tap(find.text('Save event'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Integration Event'));
    await tester.pumpAndSettle();

    expect(find.text('Check-ins: 0'), findsOneWidget);

    final payloadWidget =
        tester.widget<Text>(find.textContaining('Payload:').first);
    final payload = payloadWidget.data!.replaceFirst('Payload: ', '');

    await tester.tap(find.byIcon(Icons.qr_code_scanner));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.keyboard));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, payload);
    await tester.tap(find.text('Process'));
    await tester.pumpAndSettle();

    expect(find.text('Check-ins: 1'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.share));
    await tester.pumpAndSettle();

    expect(find.text('Export ready to share.'), findsOneWidget);
  });
}
