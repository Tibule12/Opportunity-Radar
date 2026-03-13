import 'package:firebase_core/firebase_core.dart';

class FirebaseBootstrap {
  static Future<bool> ensureInitialized() async {
    if (Firebase.apps.isNotEmpty) {
      return true;
    }

    try {
      await Firebase.initializeApp();
      return true;
    } catch (_) {
      return false;
    }
  }
}
