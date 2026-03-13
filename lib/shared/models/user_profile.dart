import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  const UserProfile({
    required this.id,
    required this.displayName,
    required this.phoneNumber,
    required this.roles,
    required this.availabilityStatus,
    required this.referralCode,
    required this.ratingAverage,
    required this.ratingCount,
    required this.completedTaskCount,
    required this.referralCount,
    required this.rewardPoints,
    required this.earningsToday,
    required this.earningsWeek,
    required this.earningsMonth,
    required this.earningsLifetime,
    required this.verificationStatus,
    required this.responseSpeedSeconds,
    required this.trustBadges,
    required this.deviceTokens,
    required this.locationAddress,
    this.photoUrl,
    this.referredBy,
    this.locationLat,
    this.locationLng,
  });

  final String id;
  final String displayName;
  final String phoneNumber;
  final String? photoUrl;
  final List<String> roles;
  final String availabilityStatus;
  final String referralCode;
  final String? referredBy;
  final double ratingAverage;
  final int ratingCount;
  final int completedTaskCount;
  final int referralCount;
  final int rewardPoints;
  final double earningsToday;
  final double earningsWeek;
  final double earningsMonth;
  final double earningsLifetime;
  final String verificationStatus;
  final int responseSpeedSeconds;
  final List<String> trustBadges;
  final List<String> deviceTokens;
  final String locationAddress;
  final double? locationLat;
  final double? locationLng;

  bool get hasLocation => locationLat != null && locationLng != null;
  bool get isWorker => roles.contains('worker');
  bool get isOnline => availabilityStatus == 'online';
  bool get isBusy => availabilityStatus == 'busy';

  bool get isComplete => displayName.trim().isNotEmpty && roles.isNotEmpty;

  String get initials {
    final segments = displayName
        .trim()
        .split(RegExp(r'\s+'))
        .where((segment) => segment.isNotEmpty)
        .toList();

    if (segments.isEmpty) {
      return '?';
    }

    if (segments.length == 1) {
      return segments.first.substring(0, 1).toUpperCase();
    }

    return (segments.first.substring(0, 1) + segments.last.substring(0, 1))
        .toUpperCase();
  }

  factory UserProfile.fromDocument(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    final location = data['location'] as Map<String, dynamic>? ?? <String, dynamic>{};
    final workerStatus = _normalizeWorkerStatus(
      data['worker_status'] ?? data['availability_status'],
    );

    return UserProfile(
      id: doc.id,
      displayName: data['display_name'] as String? ?? '',
      phoneNumber: data['phone_number'] as String? ?? '',
      photoUrl: data['photo_url'] as String?,
      roles: List<String>.from(data['roles'] as List<dynamic>? ?? const []),
      availabilityStatus: workerStatus,
      referralCode: data['referral_code'] as String? ?? '',
      referredBy: data['referred_by'] as String?,
      ratingAverage: (data['rating_average'] as num? ?? 0).toDouble(),
      ratingCount: (data['rating_count'] as num? ?? 0).toInt(),
      completedTaskCount: (data['completed_task_count'] as num? ?? 0).toInt(),
      referralCount: (data['referral_count'] as num? ?? 0).toInt(),
      rewardPoints: (data['reward_points'] as num? ?? 0).toInt(),
      earningsToday: (data['earnings_today'] as num? ?? 0).toDouble(),
      earningsWeek: (data['earnings_week'] as num? ?? 0).toDouble(),
      earningsMonth: (data['earnings_month'] as num? ?? 0).toDouble(),
      earningsLifetime: (data['earnings_lifetime'] as num? ?? 0).toDouble(),
      verificationStatus: data['verification_status'] as String? ?? 'unverified',
      responseSpeedSeconds: (data['response_speed_seconds'] as num? ?? 0).toInt(),
      trustBadges: List<String>.from(
        data['trust_badges'] as List<dynamic>? ?? const [],
      ),
      deviceTokens: List<String>.from(
        data['device_tokens'] as List<dynamic>? ?? const [],
      ),
      locationAddress: location['address_text'] as String? ?? '',
      locationLat: (location['lat'] as num?)?.toDouble(),
      locationLng: (location['lng'] as num?)?.toDouble(),
    );
  }
}

String _normalizeWorkerStatus(Object? value) {
  switch ('$value'.toLowerCase()) {
    case 'available':
    case 'online':
      return 'online';
    case 'busy':
      return 'busy';
    default:
      return 'offline';
  }
}
