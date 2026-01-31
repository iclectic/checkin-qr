import 'package:flutter_test/flutter_test.dart';

import 'package:checkin_qr/main.dart';

import 'test_hive.dart';

void main() {
  testWidgets('App shows onboarding on first launch', (WidgetTester tester) async {
    final hive = await TestHive.init();

    await tester.pumpWidget(const MeetupCheckInQrApp());
    await tester.pumpAndSettle();

    expect(find.text('Welcome to Meetup Check In QR'), findsOneWidget);

    await hive.dispose();
  });
}
