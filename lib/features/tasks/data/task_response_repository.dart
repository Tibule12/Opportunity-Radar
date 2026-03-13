import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../shared/models/task_opportunity.dart';
import '../../../shared/models/task_response.dart';

class TaskResponseRepository {
  TaskResponseRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _responsesCollection {
    return _firestore.collection('task_responses');
  }

  CollectionReference<Map<String, dynamic>> get _tasksCollection {
    return _firestore.collection('tasks');
  }

  Stream<List<TaskResponse>> watchTaskResponses(String taskId) {
    return _responsesCollection
        .where('task_id', isEqualTo: taskId)
        .orderBy('created_at', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(TaskResponse.fromDocument).toList());
  }

  Stream<List<TaskResponse>> watchResponsesByWorker(String workerId) {
    return _responsesCollection
        .where('worker_id', isEqualTo: workerId)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(TaskResponse.fromDocument).toList());
  }

  Future<void> submitResponse({
    required TaskOpportunity task,
    required String workerId,
    required String message,
    required double offeredAmount,
    required int estimatedArrivalMinutes,
  }) async {
    if (!task.isOpen) {
      throw StateError('This task is no longer accepting responses.');
    }

    if (task.createdBy == workerId) {
      throw StateError('You cannot respond to your own task.');
    }

    final duplicateCheck = await _responsesCollection
        .where('task_id', isEqualTo: task.id)
        .where('worker_id', isEqualTo: workerId)
        .limit(1)
        .get();

    if (duplicateCheck.docs.isNotEmpty) {
      throw StateError('You have already responded to this task.');
    }

    final responseRef = _responsesCollection.doc();

    await responseRef.set({
      'task_id': task.id,
      'worker_id': workerId,
      'customer_id': task.createdBy,
      'message': message.trim(),
      'offered_amount': offeredAmount,
      'estimated_arrival_minutes': estimatedArrivalMinutes,
      'status': 'pending',
      'created_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  Future<void> acceptResponse({
    required TaskOpportunity task,
    required TaskResponse acceptedResponse,
  }) async {
    final taskRef = _tasksCollection.doc(task.id);
    final acceptedRef = _responsesCollection.doc(acceptedResponse.id);

    await _firestore.runTransaction((transaction) async {
      final pendingResponses = await _responsesCollection
          .where('task_id', isEqualTo: task.id)
          .get();

      for (final doc in pendingResponses.docs) {
        transaction.update(doc.reference, {
          'status': doc.id == acceptedResponse.id ? 'accepted' : 'declined',
          'updated_at': FieldValue.serverTimestamp(),
        });
      }

      transaction.update(taskRef, {
        'status': 'matched',
        'assigned_worker_id': acceptedResponse.workerId,
        'updated_at': FieldValue.serverTimestamp(),
      });

      transaction.update(acceptedRef, {
        'status': 'accepted',
        'updated_at': FieldValue.serverTimestamp(),
      });
    });
  }
}
