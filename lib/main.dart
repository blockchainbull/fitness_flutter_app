// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:user_onboarding/providers/user_provider.dart';
import 'package:user_onboarding/config/environment.dart';
import 'package:user_onboarding/features/splash/screens/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Debug print environment variables
  Environment.debugPrint();

  try {
    if (!Environment.isConfigured) {
      print('❌ Supabase environment variables are not configured!');
      runApp(ErrorApp());
      return;
    }
    
    await Supabase.initialize(
      url: Environment.supabaseUrl,
      anonKey: Environment.supabaseAnonKey,
    );
    
    print('✅ Supabase initialized successfully');
  
  runApp(
    ChangeNotifierProvider(
      create: (_) => UserProvider()..initUser(),
      child: const MyApp(),
    ),
  );
  } catch (e) {
    print('❌ Error initializing Supabase: $e');
    runApp(ErrorApp());
  }
}



class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Health AI',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// Error screen for when Supabase isn't configured
class ErrorApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 60, color: Colors.red),
                SizedBox(height: 20),
                Text(
                  'Configuration Error',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                Text(
                  'Supabase environment variables are not configured.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 20),
                Text(
                  'URL: ${Environment.supabaseUrl.isEmpty ? "NOT SET" : "SET"}',
                  style: TextStyle(fontFamily: 'monospace'),
                ),
                Text(
                  'Key: ${Environment.supabaseAnonKey.isEmpty ? "NOT SET" : "SET"}',
                  style: TextStyle(fontFamily: 'monospace'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}