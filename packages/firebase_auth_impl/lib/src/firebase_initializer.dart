import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart' as generated;

/// Wrap Firebase.initializeApp so the app code never imports firebase_core directly.
Future<void> initFirebase() => Firebase.initializeApp(
  options: generated.DefaultFirebaseOptions.currentPlatform,
);
