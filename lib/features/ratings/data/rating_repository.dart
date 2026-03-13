import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../shared/models/task_opportunity.dart';
import '../../../shared/models/task_rating.dart';

class RatingRepository {
  RatingRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _ratingsCollection {
    return _firestore.collection('ratings');
  }

  Future<TaskRating?> fetchUserRatingForTask({
    required String taskId,
    required String fromUserId,
  }) async {
    final snapshot = await _ratingsCollection
        .where('task_id', isEqualTo: taskId)
        .where('from_user_id', isEqualTo: fromUserId)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) {
      return null;
    }

    return TaskRating.fromDocument(snapshot.docs.first);
  }

  Future<void> submitRating({
    required TaskOpportunity task,
    required String fromUserId,
    required int reliability,
    required int communication,
    required int speed,
    required int professionalism,
    required String comment,
  }) async {
    if (task.status != 'completed') {
      throw StateError('Ratings are only available after task completion.');
    }

    final counterpartId = fromUserId == task.createdBy ? task.assignedWorkerId : task.createdBy;
    if (counterpartId == null || counterpartId == fromUserId) {
      throw StateError('A valid counterpart is required before rating.');
    }

    final ratingId = '${task.id}_${fromUserId}_$counterpartId';
    final docRef = _ratingsCollection.doc(ratingId);
    final existing = await docRef.get();
    if (existing.exists) {
      throw StateError('You have already rated this task.');
    }

    await docRef.set({
      'task_id': task.id,
      'from_user_id': fromUserId,
      'to_user_id': counterpartId,
      'reliability': reliability,
      'communication': communication,
      'speed': speed,
      'professionalism': professionalism,
      'comment': comment.trim(),
      'created_at': FieldValue.serverTimestamp(),
    });
  }
}
