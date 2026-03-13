import 'package:cloud_firestore/cloud_firestore.dart';

class WorkerTaskLocation {
  const WorkerTaskLocation({
    required this.taskId,
    required this.workerId,
    required this.customerId,
    required this.latitude,
    required this.longitude,
    required this.addressText,
    this.updatedAt,
  });

  final String taskId;
  final String workerId;
  final String customerId;
  final double latitude;
  final double longitude;
  final String addressText;
  final DateTime? updatedAt;

  factory WorkerTaskLocation.fromDocument(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};

    return WorkerTaskLocation(
      taskId: data['task_id'] as String? ?? '',
      workerId: data['worker_id'] as String? ?? '',
      customerId: data['customer_id'] as String? ?? '',
      latitude: (data['lat'] as num? ?? 0).toDouble(),
      longitude: (data['lng'] as num? ?? 0).toDouble(),
      addressText: data['address_text'] as String? ?? '',
      updatedAt: (data['updated_at'] as Timestamp?)?.toDate(),
    );
  }
}
