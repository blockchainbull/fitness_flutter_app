// lib/services/platform_services.dart
// Main export file with conditional imports

// This is the magic that makes conditional compilation work!
// The compiler will choose the correct implementation based on the platform:
// - For mobile (iOS/Android): uses platform_services_mobile.dart
// - For web: uses platform_services_web.dart
// - Fallback: uses platform_services_stub.dart (should never happen)

export 'platform_services_stub.dart'
    if (dart.library.io) 'platform_services_mobile.dart'
    if (dart.library.html) 'platform_services_web.dart';

// Usage in your app:
// import 'package:user_onboarding/services/platform_services.dart';
// 
// final platformServices = PlatformServices.instance;
// 
// // Check if feature is available
// if (platformServices.isSpeechAvailable) {
//   await platformServices.startListening(
//     onResult: (text) => print(text),
//   );
// }