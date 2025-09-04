class Environment {
    static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );
  
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );
  
  static bool get isConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
  
  // Add debug method
  static void debugPrint() {
    print('🔍 Supabase URL: ${supabaseUrl.isNotEmpty ? "Set (${supabaseUrl.substring(0, 20)}...)" : "NOT SET"}');
    print('🔍 Supabase Anon Key: ${supabaseAnonKey.isNotEmpty ? "Set" : "NOT SET"}');
    print('🔍 Is Configured: $isConfigured');
  }
}