import 'package:cloud_firestore/cloud_firestore.dart';

class TaskMessage {
  const TaskMessage({
    required this.id,
    required this.taskId,
    required this.chatId,
    required this.senderId,
    required this.recipientId,
    required this.messageType,
    required this.text,
    this.offerAmount,
    this.offerCurrency,
    this.createdAt,
    this.readAt,
  });

  final String id;
  final String taskId;
  final String chatId;
  final String senderId;
  final String recipientId;
  final String messageType;
  final String text;
  final double? offerAmount;
  final String? offerCurrency;
  final DateTime? createdAt;
  final DateTime? readAt;

  bool get isSystem => messageType == 'system';
  bool get isOffer => messageType == 'offer';

  factory TaskMessage.fromDocument(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};

    return TaskMessage(
      id: doc.id,
      taskId: data['task_id'] as String? ?? '',
      chatId: data['chat_id'] as String? ?? '',
      senderId: data['sender_id'] as String? ?? '',
      recipientId: data['recipient_id'] as String? ?? '',
      messageType: data['message_type'] as String? ?? 'text',
      text: data['text'] as String? ?? '',
      offerAmount: (data['offer_payload'] as Map<String, dynamic>?)?['amount'] == null
          ? null
          : ((data['offer_payload'] as Map<String, dynamic>)['amount'] as num)
              .toDouble(),
      offerCurrency: (data['offer_payload'] as Map<String, dynamic>?)?['currency'] as String?,
      createdAt: (data['created_at'] as Timestamp?)?.toDate(),
      readAt: (data['read_at'] as Timestamp?)?.toDate(),
    );
  }
}
