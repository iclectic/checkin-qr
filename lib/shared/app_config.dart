class AppConfig {
  static const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );
  static const supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );
  static const selfCheckInBaseUrl = String.fromEnvironment(
    'SELF_CHECKIN_BASE_URL',
    defaultValue: '',
  );

  static bool get supabaseConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  static bool get selfCheckInConfigured => selfCheckInBaseUrl.trim().isNotEmpty;
}
