import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/services/location_service.dart';
import '../../../shared/models/task_opportunity.dart';
import '../../../shared/models/worker_task_location.dart';

class WorkerLocationRepository {
  WorkerLocationRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _locationsCollection {
    return _firestore.collection('worker_locations');
  }

  Stream<WorkerTaskLocation?> watchTaskLocation(String taskId) {
    return _locationsCollection.doc(taskId).snapshots().map((snapshot) {
      if (!snapshot.exists) {
        return null;
      }

      return WorkerTaskLocation.fromDocument(snapshot);
    });
  }

  Future<void> updateLocation({
    required TaskOpportunity task,
    required String workerId,
    required AppLocation location,
  }) {
    return _locationsCollection.doc(task.id).set({
      'task_id': task.id,
      'worker_id': workerId,
      'customer_id': task.createdBy,
      'lat': location.latitude,
      'lng': location.longitude,
      'address_text': location.addressText ?? '',
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  Future<void> clearLocation(String taskId) {
    return _locationsCollection.doc(taskId).delete();
  }
}
