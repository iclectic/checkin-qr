import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
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

  ThemeMode _resolveThemeMode(ThemeModeOption option) {
    switch (option) {
      case ThemeModeOption.light:
        return ThemeMode.light;
      case ThemeModeOption.dark:
        return ThemeMode.dark;
      case ThemeModeOption.system:
        return ThemeMode.system;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: Hive.box(HiveSetup.settingsBoxName).listenable(),
      builder: (context, box, _) {
        final themeMode = _resolveThemeMode(AppSettings.themeModeOption);
        return MaterialApp(
          title: 'Meetup Check In QR',
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: themeMode,
          initialRoute:
              AppSettings.onboardingSeen ? AppRoutes.home : AppRoutes.onboarding,
          onGenerateRoute: AppRoutes.onGenerateRoute,
        );
      },
    );
  }
}
