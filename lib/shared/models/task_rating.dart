import 'package:cloud_firestore/cloud_firestore.dart';

class TaskRating {
  const TaskRating({
    required this.id,
    required this.taskId,
    required this.fromUserId,
    required this.toUserId,
    required this.reliability,
    required this.communication,
    required this.speed,
    required this.professionalism,
    required this.comment,
    this.createdAt,
  });

  final String id;
  final String taskId;
  final String fromUserId;
  final String toUserId;
  final int reliability;
  final int communication;
  final int speed;
  final int professionalism;
  final String comment;
  final DateTime? createdAt;

  double get averageScore =>
      (reliability + communication + speed + professionalism) / 4;

  factory TaskRating.fromDocument(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};

    return TaskRating(
      id: doc.id,
      taskId: data['task_id'] as String? ?? '',
      fromUserId: data['from_user_id'] as String? ?? '',
      toUserId: data['to_user_id'] as String? ?? '',
      reliability: (data['reliability'] as num? ?? 0).toInt(),
      communication: (data['communication'] as num? ?? 0).toInt(),
      speed: (data['speed'] as num? ?? 0).toInt(),
      professionalism: (data['professionalism'] as num? ?? 0).toInt(),
      comment: data['comment'] as String? ?? '',
      createdAt: (data['created_at'] as Timestamp?)?.toDate(),
    );
  }
}
