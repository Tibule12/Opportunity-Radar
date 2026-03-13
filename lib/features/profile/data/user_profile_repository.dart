import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../shared/models/user_profile.dart';

class UserProfileRepository {
  UserProfileRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _usersCollection {
    return _firestore.collection('users');
  }

  Stream<UserProfile?> watchUserProfile(String uid) {
    return _usersCollection.doc(uid).snapshots().map((snapshot) {
      if (!snapshot.exists) {
        return null;
      }

      return UserProfile.fromDocument(snapshot);
    });
  }

  Future<UserProfile?> fetchUserProfile(String uid) async {
    final snapshot = await _usersCollection.doc(uid).get();
    if (!snapshot.exists) {
      return null;
    }

    return UserProfile.fromDocument(snapshot);
  }

  Future<void> upsertProfile({
    required String uid,
    required String displayName,
    required String phoneNumber,
    required List<String> roles,
    required String availabilityStatus,
    required String locationAddress,
    required double? locationLat,
    required double? locationLng,
    String? referralCodeInput,
  }) async {
    final reference = _usersCollection.doc(uid);
    final existingSnapshot = await reference.get();
    final existingData = existingSnapshot.data() ?? <String, dynamic>{};
    final normalizedStatus = _normalizeWorkerStatus(availabilityStatus);
    final normalizedReferralCode = _normalizeReferralCode(referralCodeInput);
    var referredBy = existingData['referred_by'] as String?;

    if ((referredBy == null || referredBy.trim().isEmpty) && normalizedReferralCode != null) {
      final referralSnapshot = await _usersCollection
          .where('referral_code', isEqualTo: normalizedReferralCode)
          .limit(1)
          .get();
      if (referralSnapshot.docs.isNotEmpty && referralSnapshot.docs.first.id != uid) {
        referredBy = referralSnapshot.docs.first.id;
      }
    }

    final referralCode = (existingData['referral_code'] as String?)?.trim().isNotEmpty == true
        ? existingData['referral_code'] as String
        : _buildReferralCode(displayName: displayName, uid: uid);

    await reference.set(
      {
        'display_name': displayName.trim(),
        'phone_number': phoneNumber,
        'roles': roles,
        'availability_status': normalizedStatus,
        'worker_status': normalizedStatus,
        'referral_code': referralCode,
        'referred_by': referredBy,
        'referral_count': existingData['referral_count'] ?? 0,
        'reward_points': existingData['reward_points'] ?? 0,
        'rating_average': existingData['rating_average'] ?? 0,
        'rating_count': existingData['rating_count'] ?? 0,
        'completed_task_count': existingData['completed_task_count'] ?? 0,
        'earnings_today': existingData['earnings_today'] ?? 0,
        'earnings_week': existingData['earnings_week'] ?? 0,
        'earnings_month': existingData['earnings_month'] ?? 0,
        'earnings_lifetime': existingData['earnings_lifetime'] ?? 0,
        'verification_status': existingData['verification_status'] ?? 'unverified',
        'response_speed_seconds': existingData['response_speed_seconds'] ?? 0,
        'trust_badges': existingData['trust_badges'] ?? <String>[],
        'device_tokens': existingData['device_tokens'] ?? <String>[],
        'photo_url': existingData['photo_url'],
        'location': {
          'address_text': locationAddress.trim(),
          'lat': locationLat,
          'lng': locationLng,
          'geohash': '',
        },
        'created_at': existingData['created_at'] ?? FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Stream<List<UserProfile>> watchReferredWorkers(String referrerId) {
    return _usersCollection
        .where('referred_by', isEqualTo: referrerId)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(UserProfile.fromDocument).toList());
  }

  Future<void> addDeviceToken({
    required String uid,
    required String token,
  }) {
    return _usersCollection.doc(uid).set({
      'device_tokens': FieldValue.arrayUnion([token]),
      'updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> updateAvailability({
    required String uid,
    required String availabilityStatus,
  }) {
    return updateWorkerStatus(
      uid: uid,
      workerStatus: availabilityStatus,
    );
  }

  Future<void> updateWorkerStatus({
    required String uid,
    required String workerStatus,
    String? locationAddress,
    double? locationLat,
    double? locationLng,
  }) {
    final normalizedStatus = _normalizeWorkerStatus(workerStatus);
    final payload = <String, Object?>{
      'worker_status': normalizedStatus,
      'availability_status': normalizedStatus,
      'updated_at': FieldValue.serverTimestamp(),
    };

    if (locationAddress != null || locationLat != null || locationLng != null) {
      payload['location'] = {
        'address_text': (locationAddress ?? '').trim(),
        'lat': locationLat,
        'lng': locationLng,
        'geohash': '',
      };
    }

    return _usersCollection.doc(uid).update({
      ...payload,
    });
  }
}

String _normalizeWorkerStatus(String value) {
  switch (value.trim().toLowerCase()) {
    case 'available':
    case 'online':
      return 'online';
    case 'busy':
      return 'busy';
    default:
      return 'offline';
  }
}

String? _normalizeReferralCode(String? value) {
  final normalized = value
      ?.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '')
      .trim()
      .toUpperCase();
  if (normalized == null || normalized.isEmpty) {
    return null;
  }

  return normalized;
}

String _buildReferralCode({
  required String displayName,
  required String uid,
}) {
  final base = displayName
      .replaceAll(RegExp(r'[^a-zA-Z0-9]'), '')
      .toUpperCase();
  final prefix = (base.isEmpty ? 'RADAR' : base).substring(0, (base.isEmpty ? 5 : base.length.clamp(0, 5)));
  final suffix = uid.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toUpperCase();
  final compactSuffix = suffix.substring(0, suffix.length.clamp(0, 4));
  return '$prefix$compactSuffix';
}
