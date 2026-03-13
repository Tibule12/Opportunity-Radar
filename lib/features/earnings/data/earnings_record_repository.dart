import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../shared/models/earnings_record.dart';

class EarningsRecordRepository {
  EarningsRecordRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _earningsCollection {
    return _firestore.collection('earnings_records');
  }

  Stream<List<EarningsRecord>> watchWorkerEarnings(String workerId) {
    return _earningsCollection
        .where('worker_id', isEqualTo: workerId)
        .orderBy('completed_at', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(EarningsRecord.fromDocument).toList());
  }
}