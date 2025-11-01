// lib/utils/user_diagnostic_widget.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:user_onboarding/data/managers/user_manager.dart';

class UserDiagnosticWidget extends StatelessWidget {
  const UserDiagnosticWidget({Key? key}) : super(key: key);

  Future<Map<String, dynamic>> _getDiagnostics() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = await UserManager.getCurrentUserId();
    final isLoggedIn = await UserManager.isLoggedIn();
    final userProfile = await UserManager.getCurrentUser();
    
    return {
      'shared_prefs': {
        'user_id': prefs.getString('user_id'),
        'is_logged_in': prefs.getBool('is_logged_in'),
        'onboarding_completed': prefs.getBool('onboarding_completed'),
        'user_email': prefs.getString('user_email'),
        'has_user_profile': prefs.getString('user_profile') != null,
      },
      'user_manager': {
        'user_id': userId,
        'is_logged_in': isLoggedIn,
        'user_name': userProfile?.name,
        'user_email': userProfile?.email,
      }
    };
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _getDiagnostics(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final data = snapshot.data!;
        final sharedPrefs = data['shared_prefs'] as Map<String, dynamic>;
        final userManager = data['user_manager'] as Map<String, dynamic>;

        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '🔍 USER DIAGNOSTICS',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              const Divider(color: Colors.white54),
              Text(
                'SharedPrefs user_id: ${sharedPrefs['user_id'] ?? 'NULL'}',
                style: TextStyle(
                  color: sharedPrefs['user_id'] != null 
                      ? Colors.green 
                      : Colors.red,
                  fontSize: 10,
                  fontFamily: 'monospace',
                ),
              ),
              Text(
                'SharedPrefs is_logged_in: ${sharedPrefs['is_logged_in']}',
                style: TextStyle(
                  color: sharedPrefs['is_logged_in'] == true
                      ? Colors.green
                      : Colors.red,
                  fontSize: 10,
                  fontFamily: 'monospace',
                ),
              ),
              Text(
                'SharedPrefs onboarding: ${sharedPrefs['onboarding_completed']}',
                style: TextStyle(
                  color: sharedPrefs['onboarding_completed'] == true
                      ? Colors.green
                      : Colors.red,
                  fontSize: 10,
                  fontFamily: 'monospace',
                ),
              ),
              Text(
                'Has user_profile JSON: ${sharedPrefs['has_user_profile']}',
                style: TextStyle(
                  color: sharedPrefs['has_user_profile'] == true
                      ? Colors.green
                      : Colors.red,
                  fontSize: 10,
                  fontFamily: 'monospace',
                ),
              ),
              const Divider(color: Colors.white54),
              Text(
                'UserManager user_id: ${userManager['user_id'] ?? 'NULL'}',
                style: TextStyle(
                  color: userManager['user_id'] != null
                      ? Colors.green
                      : Colors.red,
                  fontSize: 10,
                  fontFamily: 'monospace',
                ),
              ),
              Text(
                'UserManager is_logged_in: ${userManager['is_logged_in']}',
                style: TextStyle(
                  color: userManager['is_logged_in'] == true
                      ? Colors.green
                      : Colors.red,
                  fontSize: 10,
                  fontFamily: 'monospace',
                ),
              ),
              Text(
                'User name: ${userManager['user_name'] ?? 'NULL'}',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 10,
                  fontFamily: 'monospace',
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    sharedPrefs['user_id'] != null &&
                        userManager['user_id'] != null
                        ? Icons.check_circle
                        : Icons.error,
                    color: sharedPrefs['user_id'] != null &&
                        userManager['user_id'] != null
                        ? Colors.green
                        : Colors.red,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      sharedPrefs['user_id'] != null &&
                          userManager['user_id'] != null
                          ? 'User authenticated ✓'
                          : 'User NOT authenticated ✗',
                      style: TextStyle(
                        color: sharedPrefs['user_id'] != null &&
                            userManager['user_id'] != null
                            ? Colors.green
                            : Colors.red,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

// HOW TO USE:
// Add this to your DashboardHome widget temporarily:
// 
// @override
// Widget build(BuildContext context) {
//   return Scaffold(
//     body: Stack(
//       children: [
//         // Your existing dashboard content
//         ...
//         
//         // Add this at the bottom
//         const Positioned(
//           bottom: 80,
//           left: 0,
//           right: 0,
//           child: UserDiagnosticWidget(),
//         ),
//       ],
//     ),
//   );
// }