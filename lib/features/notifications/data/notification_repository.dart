import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../shared/models/app_notification.dart';

class NotificationRepository {
  NotificationRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _notificationsCollection {
    return _firestore.collection('notifications');
  }

  Stream<List<AppNotification>> watchUserNotifications(String userId) {
    return _notificationsCollection
        .where('user_id', isEqualTo: userId)
        .orderBy('created_at', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(AppNotification.fromDocument).toList());
  }

  Future<void> markAsRead(String notificationId) {
    return _notificationsCollection.doc(notificationId).update({
      'read': true,
      'read_at': FieldValue.serverTimestamp(),
    });
  }

  Future<void> markAllAsRead(List<String> notificationIds) async {
    if (notificationIds.isEmpty) {
      return;
    }

    final batch = _firestore.batch();
    for (final notificationId in notificationIds) {
      batch.update(_notificationsCollection.doc(notificationId), {
        'read': true,
        'read_at': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
  }
}