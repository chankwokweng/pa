import 'package:firebase_core/firebase_core.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform => web;

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: String.fromEnvironment('FIREBASE_API_KEY'),
    authDomain: String.fromEnvironment('FIREBASE_AUTH_DOMAIN'),
    projectId: String.fromEnvironment('FIREBASE_PROJECT_ID'),
    storageBucket: String.fromEnvironment('FIREBASE_STORAGE_BUCKET'),
    messagingSenderId: String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID'),
    appId: String.fromEnvironment('FIREBASE_APP_ID'),
  );
}
