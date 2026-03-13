import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';

import '../../features/profile/data/user_profile_repository.dart';

class PushNotificationService {
  PushNotificationService(this._messaging, this._profiles);

  final FirebaseMessaging _messaging;
  final UserProfileRepository _profiles;

  StreamSubscription<String>? _tokenRefreshSubscription;
  String? _activeUserId;

  Future<void> syncForUser(String? userId) async {
    if (userId == null || userId.trim().isEmpty) {
      _activeUserId = null;
      await _tokenRefreshSubscription?.cancel();
      _tokenRefreshSubscription = null;
      return;
    }

    final permission = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: true,
    );
    if (!_isAuthorized(permission)) {
      return;
    }

    final token = await _messaging.getToken();
    if (token != null && token.trim().isNotEmpty) {
      await _profiles.addDeviceToken(uid: userId, token: token);
    }

    if (_activeUserId == userId && _tokenRefreshSubscription != null) {
      return;
    }

    _activeUserId = userId;
    await _tokenRefreshSubscription?.cancel();
    _tokenRefreshSubscription = _messaging.onTokenRefresh.listen((token) async {
      if (token.trim().isEmpty || _activeUserId == null) {
        return;
      }

      await _profiles.addDeviceToken(uid: _activeUserId!, token: token);
    });
  }

  void dispose() {
    _tokenRefreshSubscription?.cancel();
  }

  bool _isAuthorized(NotificationSettings settings) {
    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }
}