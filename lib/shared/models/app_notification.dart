import 'package:cloud_firestore/cloud_firestore.dart';

class AppNotification {
  const AppNotification({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.body,
    required this.read,
    this.taskId,
    this.createdAt,
    this.readAt,
  });

  final String id;
  final String userId;
  final String type;
  final String title;
  final String body;
  final String? taskId;
  final bool read;
  final DateTime? createdAt;
  final DateTime? readAt;

  factory AppNotification.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};

    return AppNotification(
      id: doc.id,
      userId: data['user_id'] as String? ?? '',
      type: data['type'] as String? ?? 'system',
      title: data['title'] as String? ?? '',
      body: data['body'] as String? ?? '',
      taskId: data['task_id'] as String?,
      read: data['read'] as bool? ?? false,
      createdAt: (data['created_at'] as Timestamp?)?.toDate(),
      readAt: (data['read_at'] as Timestamp?)?.toDate(),
    );
  }
}