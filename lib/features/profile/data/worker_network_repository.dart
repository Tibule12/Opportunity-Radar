import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../shared/models/worker_network_entry.dart';

class WorkerNetworkRepository {
  WorkerNetworkRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _networksCollection {
    return _firestore.collection('worker_networks');
  }

  Stream<List<WorkerNetworkEntry>> watchTrustedWorkers(String ownerUserId) {
    return _networksCollection
        .where('owner_user_id', isEqualTo: ownerUserId)
        .where('relationship_type', isEqualTo: 'trusted')
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(WorkerNetworkEntry.fromDocument).toList());
  }

  Stream<bool> watchTrustedStatus({
    required String ownerUserId,
    required String workerUserId,
  }) {
    return _networksCollection
        .doc(_trustedWorkerId(ownerUserId: ownerUserId, workerUserId: workerUserId))
        .snapshots()
        .map((snapshot) => snapshot.exists);
  }

  Future<void> trustWorker({
    required String ownerUserId,
    required String workerUserId,
  }) {
    return _networksCollection
        .doc(_trustedWorkerId(ownerUserId: ownerUserId, workerUserId: workerUserId))
        .set({
      'owner_user_id': ownerUserId,
      'worker_user_id': workerUserId,
      'relationship_type': 'trusted',
      'created_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> removeTrustedWorker({
    required String ownerUserId,
    required String workerUserId,
  }) {
    return _networksCollection
        .doc(_trustedWorkerId(ownerUserId: ownerUserId, workerUserId: workerUserId))
        .delete();
  }

  String _trustedWorkerId({
    required String ownerUserId,
    required String workerUserId,
  }) {
    return '${ownerUserId}_${workerUserId}';
  }
}