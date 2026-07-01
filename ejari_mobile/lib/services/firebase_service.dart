import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import '../firebase_options.dart';

class FirebaseService {
  static bool isInitialized = false;

  /// Initializes Firebase natively using flutterfire configuration
  static Future<void> initialize() async {
    try {
      if (Firebase.apps.isNotEmpty) {
        isInitialized = true;
        if (kDebugMode) {
          print('✅ Firebase already initialized');
        }
        return;
      }
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      isInitialized = true;
      if (kDebugMode) {
        print('✅ Firebase Initialized Successfully');
      }
    } catch (e) {
      final errorText = e.toString();
      if (errorText.contains('duplicate-app') ||
          errorText.contains('already exists')) {
        isInitialized = true;
        if (kDebugMode) {
          print('✅ Firebase already initialized (duplicate-app ignored)');
        }
        return;
      }
      if (kDebugMode) {
        print('⚠️ Firebase Initialization Failed:');
        print(
            'Did you run `flutterfire configure`? The firebase_options.dart file might be missing or incorrect.');
        print('Error Details: $e');
      }
      isInitialized = false;
    }
  }
}
