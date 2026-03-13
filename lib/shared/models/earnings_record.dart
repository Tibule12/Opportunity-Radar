import 'package:cloud_firestore/cloud_firestore.dart';

class EarningsRecord {
  const EarningsRecord({
    required this.id,
    required this.workerId,
    required this.customerId,
    required this.taskId,
    required this.agreedAmount,
    required this.currency,
    required this.paymentSettlement,
    this.taskTitle,
    this.completedAt,
  });

  final String id;
  final String workerId;
  final String customerId;
  final String taskId;
  final double agreedAmount;
  final String currency;
  final String paymentSettlement;
  final String? taskTitle;
  final DateTime? completedAt;

  factory EarningsRecord.fromDocument(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};

    return EarningsRecord(
      id: doc.id,
      workerId: data['worker_id'] as String? ?? '',
      customerId: data['customer_id'] as String? ?? '',
      taskId: data['task_id'] as String? ?? '',
      agreedAmount: (data['agreed_amount'] as num? ?? 0).toDouble(),
      currency: data['currency'] as String? ?? 'ZAR',
      paymentSettlement: data['payment_settlement'] as String? ?? 'external',
      taskTitle: data['task_title'] as String?,
      completedAt: (data['completed_at'] as Timestamp?)?.toDate(),
    );
  }
}