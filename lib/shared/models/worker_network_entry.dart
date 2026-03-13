import 'package:cloud_firestore/cloud_firestore.dart';

class WorkerNetworkEntry {
  const WorkerNetworkEntry({
    required this.id,
    required this.ownerUserId,
    required this.workerUserId,
    required this.relationshipType,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String ownerUserId;
  final String workerUserId;
  final String relationshipType;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isTrusted => relationshipType == 'trusted';

  factory WorkerNetworkEntry.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};

    return WorkerNetworkEntry(
      id: doc.id,
      ownerUserId: data['owner_user_id'] as String? ?? '',
      workerUserId: data['worker_user_id'] as String? ?? '',
      relationshipType: data['relationship_type'] as String? ?? 'trusted',
      createdAt: (data['created_at'] as Timestamp?)?.toDate(),
      updatedAt: (data['updated_at'] as Timestamp?)?.toDate(),
    );
  }
}