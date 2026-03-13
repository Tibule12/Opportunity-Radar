import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';

class AuthRepository {
  AuthRepository(this._auth);

  final FirebaseAuth _auth;

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  Future<PhoneAuthChallenge> sendOtp(String phoneNumber) async {
    final completer = Completer<PhoneAuthChallenge>();

    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (credential) async {
        await _auth.signInWithCredential(credential);
        if (!completer.isCompleted) {
          completer.complete(const PhoneAuthChallenge(autoVerified: true));
        }
      },
      verificationFailed: (exception) {
        if (!completer.isCompleted) {
          completer.completeError(
            AuthException(exception.message ?? 'Phone verification failed.'),
          );
        }
      },
      codeSent: (verificationId, _) {
        if (!completer.isCompleted) {
          completer.complete(
            PhoneAuthChallenge(verificationId: verificationId),
          );
        }
      },
      codeAutoRetrievalTimeout: (verificationId) {
        if (!completer.isCompleted) {
          completer.complete(
            PhoneAuthChallenge(verificationId: verificationId),
          );
        }
      },
    );

    return completer.future;
  }

  Future<UserCredential> verifyOtp({
    required String verificationId,
    required String smsCode,
  }) {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );

    return _auth.signInWithCredential(credential);
  }

  Future<void> signOut() => _auth.signOut();
}

class PhoneAuthChallenge {
  const PhoneAuthChallenge({
    this.verificationId,
    this.autoVerified = false,
  });

  final String? verificationId;
  final bool autoVerified;
}

class AuthException implements Exception {
  const AuthException(this.message);

  final String message;

  @override
  String toString() => message;
}
