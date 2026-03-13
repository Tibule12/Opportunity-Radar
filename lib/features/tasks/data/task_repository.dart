import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../shared/models/task_opportunity.dart';

class TaskRepository {
  TaskRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _tasksCollection {
    return _firestore.collection('tasks');
  }

  Stream<List<TaskOpportunity>> watchOpenTasks() {
    return _tasksCollection
        .where('status', isEqualTo: 'open')
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) {
      final now = DateTime.now();

      return snapshot.docs
          .map(TaskOpportunity.fromDocument)
          .where((task) => task.expiresAt == null || task.expiresAt!.isAfter(now))
          .toList();
    });
  }

  Stream<TaskOpportunity?> watchTask(String taskId) {
    return _tasksCollection.doc(taskId).snapshots().map((snapshot) {
      if (!snapshot.exists) {
        return null;
      }

      return TaskOpportunity.fromDocument(snapshot);
    });
  }

  Stream<List<TaskOpportunity>> watchTasksCreatedBy(String userId) {
    return _tasksCollection
        .where('created_by', isEqualTo: userId)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(TaskOpportunity.fromDocument).toList());
  }

  Stream<List<TaskOpportunity>> watchAssignedTasks(String userId) {
    return _tasksCollection
        .where('assigned_worker_id', isEqualTo: userId)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(TaskOpportunity.fromDocument).toList());
  }

  Future<void> createTask({
    required String createdBy,
    required String title,
    required String description,
    required String category,
    required double budgetAmount,
    required String locationAddress,
    required double? locationLat,
    required double? locationLng,
    required Duration expiresIn,
  }) async {
    final now = DateTime.now();

    await _tasksCollection.add({
      'title': title.trim(),
      'description': description.trim(),
      'category': category,
      'budget_amount': budgetAmount,
      'currency': 'ZAR',
      'status': 'open',
      'created_by': createdBy,
      'assigned_worker_id': null,
      'location': {
        'address_text': locationAddress.trim(),
        'lat': locationLat,
        'lng': locationLng,
        'geohash': '',
      },
      'photo_urls': <String>[],
      'notified_radius_meters': 500,
      'workers_notified': 0,
      'response_count': 0,
      'responses_received': 0,
      'distribution_stage': 'initial',
      'view_count': 0,
      'expires_at': Timestamp.fromDate(now.add(expiresIn)),
      'created_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  Future<void> registerTaskView({
    required String taskId,
  }) {
    return _tasksCollection.doc(taskId).update({
      'view_count': FieldValue.increment(1),
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  Future<void> repostTask({
    required TaskOpportunity task,
  }) {
    return createTask(
      createdBy: task.createdBy,
      title: task.title,
      description: task.description,
      category: task.category,
      budgetAmount: task.budgetAmount,
      locationAddress: task.locationAddress,
      locationLat: task.locationLat,
      locationLng: task.locationLng,
      expiresIn: const Duration(hours: 2),
    );
  }

  Future<void> markInProgress({
    required TaskOpportunity task,
    required String actorId,
  }) async {
    if (task.assignedWorkerId == null) {
      throw StateError('A worker must be selected before starting this task.');
    }

    if (actorId != task.createdBy && actorId != task.assignedWorkerId) {
      throw StateError('Only task participants can start this task.');
    }

    if (task.status != 'matched') {
      throw StateError('Only matched tasks can move to in progress.');
    }

    await _tasksCollection.doc(task.id).update({
      'status': 'in_progress',
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  Future<void> markCompleted({
    required TaskOpportunity task,
    required String actorId,
  }) async {
    if (actorId != task.createdBy && actorId != task.assignedWorkerId) {
      throw StateError('Only task participants can complete this task.');
    }

    if (task.status != 'matched' && task.status != 'in_progress') {
      throw StateError('Only active tasks can be completed.');
    }

    await _tasksCollection.doc(task.id).update({
      'status': 'completed',
      'completed_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    });
  }
}
