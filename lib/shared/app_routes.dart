import 'package:flutter/material.dart';

import '../screens/create_event_screen.dart';
import '../screens/attendance_list_screen.dart';
import '../screens/event_detail_screen.dart';
import '../screens/home_screen.dart';
import '../screens/manual_check_in_screen.dart';
import '../screens/scanner_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/onboarding_screen.dart';

class AppRoutes {
  static const home = '/';
  static const createEvent = '/create-event';
  static const eventDetail = '/event-detail';
  static const attendance = '/attendance';
  static const scanner = '/scanner';
  static const manualCheckIn = '/manual-check-in';
  static const settingsRoute = '/settings';
  static const onboarding = '/onboarding';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case home:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      case onboarding:
        return MaterialPageRoute(builder: (_) => const OnboardingScreen());
      case createEvent:
        return MaterialPageRoute(builder: (_) => const CreateEventScreen());
      case eventDetail:
        final eventId = settings.arguments as String;
        return MaterialPageRoute(
          builder: (_) => EventDetailScreen(eventId: eventId),
        );
      case attendance:
        final eventId = settings.arguments as String;
        return MaterialPageRoute(
          builder: (_) => AttendanceListScreen(eventId: eventId),
        );
      case scanner:
        final eventId = settings.arguments as String;
        return MaterialPageRoute(
          builder: (_) => ScannerScreen(eventId: eventId),
        );
      case manualCheckIn:
        final eventId = settings.arguments as String;
        return MaterialPageRoute(
          builder: (_) => ManualCheckInScreen(eventId: eventId),
        );
      case settingsRoute:
        return MaterialPageRoute(builder: (_) => const SettingsScreen());
      default:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text('Route not found')),
          ),
        );
    }
  }
}
