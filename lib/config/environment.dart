// lib/config/environment.dart
class Environment {
  // For web deployment, use compile-time constants
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '', // Add your default or leave empty
  );
  
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '', // Add your default or leave empty
  );
  
  static const String backendUrl = String.fromEnvironment(
    'BACKEND_URL',
    defaultValue: 'https://health-ai-backend.onrender.com',
  );
  
  static bool get isConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
  
  static void debugPrint() {
    print('🔍 Supabase URL: ${supabaseUrl.isNotEmpty ? "Set" : "NOT SET"}');
    print('🔍 Supabase Anon Key: ${supabaseAnonKey.isNotEmpty ? "Set" : "NOT SET"}');
    print('🔍 Backend URL: $backendUrl');
    print('🔍 Is Configured: $isConfigured');
  }
}