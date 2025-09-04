class Environment {

  static const String supabaseUrl = "https://wehzxcqudlfvewilgokf.supabase.co";
  static const String supabaseAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndlaHp4Y3F1ZGxmdmV3aWxnb2tmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTUyODk5OTMsImV4cCI6MjA3MDg2NTk5M30.qldRBqk3SYLrtoARhhBDLBkUNdQ218vI0fonsRXR3_c";


  // static const String supabaseUrl = String.fromEnvironment(
  //   'SUPABASE_URL',
  //   defaultValue: '',
  // );
  
  // static const String supabaseAnonKey = String.fromEnvironment(
  //   'SUPABASE_ANON_KEY',
  //   defaultValue: '',
  // );
  
  // static bool get isConfigured =>
  //     supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
  
  // // Add debug method
  // static void debugPrint() {
  //   print('🔍 Supabase URL: ${supabaseUrl.isNotEmpty ? "Set (${supabaseUrl.substring(0, 20)}...)" : "NOT SET"}');
  //   print('🔍 Supabase Anon Key: ${supabaseAnonKey.isNotEmpty ? "Set" : "NOT SET"}');
  //   print('🔍 Is Configured: $isConfigured');
  //}
}