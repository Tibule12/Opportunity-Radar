import 'package:cloud_firestore/cloud_firestore.dart';

class TaskResponse {
  const TaskResponse({
    required this.id,
    required this.taskId,
    required this.workerId,
    required this.customerId,
    required this.message,
    required this.offeredAmount,
    required this.estimatedArrivalMinutes,
    required this.status,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String taskId;
  final String workerId;
  final String customerId;
  final String message;
  final double offeredAmount;
  final int estimatedArrivalMinutes;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isAccepted => status == 'accepted';

  factory TaskResponse.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};

    return TaskResponse(
      id: doc.id,
      taskId: data['task_id'] as String? ?? '',
      workerId: data['worker_id'] as String? ?? '',
      customerId: data['customer_id'] as String? ?? '',
      message: data['message'] as String? ?? '',
      offeredAmount: (data['offered_amount'] as num? ?? 0).toDouble(),
      estimatedArrivalMinutes: (data['estimated_arrival_minutes'] as num? ?? 0).toInt(),
      status: data['status'] as String? ?? 'pending',
      createdAt: (data['created_at'] as Timestamp?)?.toDate(),
      updatedAt: (data['updated_at'] as Timestamp?)?.toDate(),
    );
  }
}
