// lib/config/home_routes.dart
import 'package:flutter/material.dart';
import 'package:user_onboarding/features/home/screens/exercise_history_screen.dart';
import 'package:user_onboarding/features/auth/screens/login_screens.dart';
import 'package:user_onboarding/data/models/user_profile.dart';

class HomeRoutes {
 static const String exerciseHistory = '/exercise_history';
 static const String login = '/login';
 
 static Route<dynamic> generateRoute(RouteSettings settings) {
   switch (settings.name) {
     case exerciseHistory:
       final args = settings.arguments as ExerciseHistoryArgs;
       return MaterialPageRoute(
         builder: (context) => ExerciseHistoryScreen(
           userProfile: args.userProfile,
           exercises: args.exercises,
         ),
       );
     case login:
       return MaterialPageRoute(
         builder: (context) => const LoginScreen(),
       );
     default:
       return MaterialPageRoute(
         builder: (_) => Scaffold(
           body: Center(
             child: Text('No route defined for ${settings.name}'),
           ),
         ),
       );
   }
 }
}

class ExerciseHistoryArgs {
 final UserProfile userProfile;
 final List<Map<String, dynamic>> exercises;
 
 ExerciseHistoryArgs({
   required this.userProfile,
   required this.exercises,
 });
}