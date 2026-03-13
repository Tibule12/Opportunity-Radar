import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../shared/models/task_message.dart';
import '../../../shared/models/task_opportunity.dart';
import '../../../shared/utils/chat_utils.dart';

class MessageRepository {
  MessageRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _messagesCollection {
    return _firestore.collection('messages');
  }

  Stream<List<TaskMessage>> watchMessages({
    required String taskId,
    required String customerId,
    required String workerId,
  }) {
    final chatId = taskChatId(
      taskId: taskId,
      customerId: customerId,
      workerId: workerId,
    );

    return _messagesCollection
        .where('chat_id', isEqualTo: chatId)
        .orderBy('created_at', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(TaskMessage.fromDocument).toList());
  }

  Future<void> sendTextMessage({
    required TaskOpportunity task,
    required String senderId,
    required String text,
  }) async {
    await _createMessage(
      task: task,
      senderId: senderId,
      messageType: 'text',
      text: text.trim(),
      offerPayload: null,
    );
  }

  Future<void> sendOfferMessage({
    required TaskOpportunity task,
    required String senderId,
    required double amount,
    String? note,
  }) async {
    final text = (note == null || note.trim().isEmpty)
        ? 'Offer: ${task.currency} ${amount.toStringAsFixed(2)}'
        : note.trim();

    await _createMessage(
      task: task,
      senderId: senderId,
      messageType: 'offer',
      text: text,
      offerPayload: {
        'amount': amount,
        'currency': task.currency,
      },
    );
  }

  Future<void> _createMessage({
    required TaskOpportunity task,
    required String senderId,
    required String messageType,
    required String text,
    required Map<String, Object?>? offerPayload,
  }) async {
    final workerId = task.assignedWorkerId;
    if (workerId == null) {
      throw StateError('Chat is only available after a worker is selected.');
    }

    final recipientId = senderId == task.createdBy ? workerId : task.createdBy;
    final chatId = taskChatId(
      taskId: task.id,
      customerId: task.createdBy,
      workerId: workerId,
    );

    await _messagesCollection.add({
      'task_id': task.id,
      'chat_id': chatId,
      'sender_id': senderId,
      'recipient_id': recipientId,
      'message_type': messageType,
      'text': text,
      'location_payload': null,
      'offer_payload': offerPayload,
      'created_at': FieldValue.serverTimestamp(),
      'read_at': null,
    });
  }
}
