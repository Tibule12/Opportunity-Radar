import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'Firebase is not configured for web yet. Run `flutterfire configure` from the repo root to generate lib/firebase_options.dart.',
      );
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
        throw UnsupportedError(
          'Firebase config files have not been generated yet. Run `flutterfire configure` from the repo root.',
        );
      case TargetPlatform.linux:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
        throw UnsupportedError(
          'Firebase desktop options have not been generated yet. Run `flutterfire configure` from the repo root to replace lib/firebase_options.dart.',
        );
      case TargetPlatform.fuchsia:
        throw UnsupportedError('Fuchsia is not configured for this project.');
    }
  }
}