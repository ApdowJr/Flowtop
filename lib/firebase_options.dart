import 'package:firebase_core/firebase_core.dart';

/// Firebase options for the flowTop Android app.
///
/// Values obtained from google-services.json (android/app/google-services.json).
/// These are configuration values (not secrets) and are safe to commit.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform => const FirebaseOptions(
        apiKey: 'AIzaSyCtcUqqUCWuHEcmuIy9lior6kb_gompMZs',
        appId: '1:685098135756:android:aae5f30286559444ded269',
        messagingSenderId: '685098135756',
        projectId: 'flowtop-e68b6',
        storageBucket: 'flowtop-e68b6.firebasestorage.app',
      );

  static FirebaseOptions get android => currentPlatform;
  static FirebaseOptions get ios => currentPlatform;
  static FirebaseOptions get web => currentPlatform;
  static FirebaseOptions get macos => currentPlatform;
  static FirebaseOptions get windows => currentPlatform;
  static FirebaseOptions get linux => currentPlatform;
}
