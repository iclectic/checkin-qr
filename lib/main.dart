import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'storage/hive_setup.dart';
import 'shared/app_config.dart';
import 'shared/app_routes.dart';
import 'shared/app_theme.dart';
import 'storage/app_settings.dart';

Future<void> main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await HiveSetup.init();
  if (AppConfig.supabaseConfigured) {
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      anonKey: AppConfig.supabaseAnonKey,
    );
  }
  runApp(const MeetupCheckInQrApp());
}

class MeetupCheckInQrApp extends StatelessWidget {
  const MeetupCheckInQrApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Meetup Check In QR',
      theme: AppTheme.light(),
      initialRoute:
          AppSettings.onboardingSeen ? AppRoutes.home : AppRoutes.onboarding,
      onGenerateRoute: AppRoutes.onGenerateRoute,
    );
  }
}
