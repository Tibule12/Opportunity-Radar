import 'package:cloud_firestore/cloud_firestore.dart';

class TaskOpportunity {
  const TaskOpportunity({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.budgetAmount,
    required this.currency,
    required this.status,
    required this.createdBy,
    required this.locationAddress,
    this.locationLat,
    this.locationLng,
    required this.photoUrls,
    required this.notifiedRadiusMeters,
    required this.responseCount,
    required this.responsesReceived,
    required this.viewCount,
    required this.workersNotified,
    required this.distributionStage,
    this.assignedWorkerId,
    this.createdAt,
    this.updatedAt,
    this.expiresAt,
    this.completedAt,
  });

  final String id;
  final String title;
  final String description;
  final String category;
  final double budgetAmount;
  final String currency;
  final String status;
  final String createdBy;
  final String? assignedWorkerId;
  final String locationAddress;
  final double? locationLat;
  final double? locationLng;
  final List<String> photoUrls;
  final int notifiedRadiusMeters;
  final int responseCount;
  final int responsesReceived;
  final int viewCount;
  final int workersNotified;
  final String distributionStage;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? expiresAt;
  final DateTime? completedAt;

  bool get isOpen => status == 'open';
  bool get hasCoordinates => locationLat != null && locationLng != null;
  bool get isExpired => status == 'expired' || (expiresAt != null && expiresAt!.isBefore(DateTime.now()));
  bool get isUrgent {
    if (expiresAt == null || isExpired) {
      return false;
    }

    return expiresAt!.difference(DateTime.now()).inMinutes <= 10;
  }

  bool isOwnedBy(String uid) => createdBy == uid;

  factory TaskOpportunity.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    final location = data['location'] as Map<String, dynamic>? ?? <String, dynamic>{};

    return TaskOpportunity(
      id: doc.id,
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      category: data['category'] as String? ?? 'other',
      budgetAmount: (data['budget_amount'] as num? ?? 0).toDouble(),
      currency: data['currency'] as String? ?? 'ZAR',
      status: data['status'] as String? ?? 'open',
      createdBy: data['created_by'] as String? ?? '',
      assignedWorkerId: data['assigned_worker_id'] as String?,
      locationAddress: location['address_text'] as String? ?? 'Location not provided',
      locationLat: (location['lat'] as num?)?.toDouble(),
      locationLng: (location['lng'] as num?)?.toDouble(),
      photoUrls: List<String>.from(data['photo_urls'] as List<dynamic>? ?? const []),
      notifiedRadiusMeters: (data['notified_radius_meters'] as num? ?? 500).toInt(),
      responseCount: (data['response_count'] as num? ?? 0).toInt(),
      responsesReceived: (data['responses_received'] as num? ?? data['response_count'] as num? ?? 0).toInt(),
      viewCount: (data['view_count'] as num? ?? 0).toInt(),
      workersNotified: (data['workers_notified'] as num? ?? 0).toInt(),
      distributionStage: data['distribution_stage'] as String? ?? 'initial',
      createdAt: (data['created_at'] as Timestamp?)?.toDate(),
      updatedAt: (data['updated_at'] as Timestamp?)?.toDate(),
      expiresAt: (data['expires_at'] as Timestamp?)?.toDate(),
      completedAt: (data['completed_at'] as Timestamp?)?.toDate(),
    );
  }
}
