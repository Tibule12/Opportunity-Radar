import '../models/task_opportunity.dart';
import '../models/user_profile.dart';
import 'distance_utils.dart';

List<TaskOpportunity> visibleTasksForProfile({
  required List<TaskOpportunity> tasks,
  required UserProfile? currentProfile,
  required String? currentUserId,
}) {
  final isWorker = currentProfile?.roles.contains('worker') ?? false;
  final workerAvailable = !isWorker || currentProfile?.availabilityStatus == 'online';

  final filtered = tasks.where((task) {
    final isOwnTask = currentUserId != null && task.isOwnedBy(currentUserId);
    if (isOwnTask) {
      return true;
    }

    return workerAvailable;
  }).toList();

  filtered.sort((left, right) {
    final leftDistance = distanceFromProfile(currentProfile, left);
    final rightDistance = distanceFromProfile(currentProfile, right);

    if (leftDistance == null && rightDistance == null) {
      final rightCreated = right.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final leftCreated = left.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return rightCreated.compareTo(leftCreated);
    }

    if (leftDistance == null) {
      return 1;
    }
    if (rightDistance == null) {
      return -1;
    }

    return leftDistance.compareTo(rightDistance);
  });

  return filtered;
}

double? distanceFromProfile(UserProfile? profile, TaskOpportunity task) {
  if (profile == null || !profile.hasLocation || !task.hasCoordinates) {
    return null;
  }

  return distanceInKm(
    fromLat: profile.locationLat!,
    fromLng: profile.locationLng!,
    toLat: task.locationLat!,
    toLng: task.locationLng!,
  );
}
