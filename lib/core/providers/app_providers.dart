import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/data/auth_repository.dart';
import '../../features/chat/data/message_repository.dart';
import '../../features/earnings/data/earnings_record_repository.dart';
import '../../features/notifications/data/notification_repository.dart';
import '../../features/profile/data/user_profile_repository.dart';
import '../../features/profile/data/worker_network_repository.dart';
import '../../features/ratings/data/rating_repository.dart';
import '../../features/tasks/data/task_repository.dart';
import '../../features/tasks/data/task_response_repository.dart';
import '../../features/tasks/data/worker_location_repository.dart';
import '../services/location_service.dart';
import '../services/push_notification_service.dart';
import '../../shared/models/app_notification.dart';
import '../../shared/models/earnings_record.dart';
import '../../shared/models/task_message.dart';
import '../../shared/models/task_opportunity.dart';
import '../../shared/models/task_rating.dart';
import '../../shared/models/task_response.dart';
import '../../shared/models/user_profile.dart';
import '../../shared/models/worker_network_entry.dart';
import '../../shared/models/worker_task_location.dart';
import '../../shared/utils/chat_utils.dart';

final firebaseReadyProvider = Provider<bool>((ref) => false);

final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
});

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

final firebaseMessagingProvider = Provider<FirebaseMessaging>((ref) {
  return FirebaseMessaging.instance;
});

final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(firebaseAuthProvider));
});

final userProfileRepositoryProvider = Provider<UserProfileRepository>((ref) {
  return UserProfileRepository(ref.watch(firestoreProvider));
});

final workerNetworkRepositoryProvider = Provider<WorkerNetworkRepository>((ref) {
  return WorkerNetworkRepository(ref.watch(firestoreProvider));
});

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  return TaskRepository(ref.watch(firestoreProvider));
});

final taskResponseRepositoryProvider = Provider<TaskResponseRepository>((ref) {
  return TaskResponseRepository(ref.watch(firestoreProvider));
});

final workerLocationRepositoryProvider = Provider<WorkerLocationRepository>((ref) {
  return WorkerLocationRepository(ref.watch(firestoreProvider));
});

final messageRepositoryProvider = Provider<MessageRepository>((ref) {
  return MessageRepository(ref.watch(firestoreProvider));
});

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository(ref.watch(firestoreProvider));
});

final earningsRecordRepositoryProvider = Provider<EarningsRecordRepository>((ref) {
  return EarningsRecordRepository(ref.watch(firestoreProvider));
});

final pushNotificationServiceProvider = Provider<PushNotificationService>((ref) {
  final service = PushNotificationService(
    ref.watch(firebaseMessagingProvider),
    ref.watch(userProfileRepositoryProvider),
  );
  ref.onDispose(service.dispose);
  return service;
});

final ratingRepositoryProvider = Provider<RatingRepository>((ref) {
  return RatingRepository(ref.watch(firestoreProvider));
});

final authStateChangesProvider = StreamProvider<User?>((ref) {
  return ref.watch(firebaseAuthProvider).authStateChanges();
});

final currentUserProfileProvider = StreamProvider<UserProfile?>((ref) {
  final authState = ref.watch(authStateChangesProvider);
  final profileRepository = ref.watch(userProfileRepositoryProvider);

  return authState.when(
    data: (user) {
      if (user == null) {
        return Stream.value(null);
      }

      return profileRepository.watchUserProfile(user.uid);
    },
    loading: () => Stream.value(null),
    error: (_, __) => Stream.value(null),
  );
});

final userProfileByIdProvider = StreamProvider.family<UserProfile?, String>((ref, userId) {
  return ref.watch(userProfileRepositoryProvider).watchUserProfile(userId);
});

final openTasksProvider = StreamProvider<List<TaskOpportunity>>((ref) {
  return ref.watch(taskRepositoryProvider).watchOpenTasks();
});

final createdTasksProvider = StreamProvider<List<TaskOpportunity>>((ref) {
  final userId = ref.watch(firebaseAuthProvider).currentUser?.uid;
  if (userId == null) {
    return Stream.value(const <TaskOpportunity>[]);
  }

  return ref.watch(taskRepositoryProvider).watchTasksCreatedBy(userId);
});

final assignedTasksProvider = StreamProvider<List<TaskOpportunity>>((ref) {
  final userId = ref.watch(firebaseAuthProvider).currentUser?.uid;
  if (userId == null) {
    return Stream.value(const <TaskOpportunity>[]);
  }

  return ref.watch(taskRepositoryProvider).watchAssignedTasks(userId);
});

final taskDetailProvider = StreamProvider.family<TaskOpportunity?, String>((ref, taskId) {
  return ref.watch(taskRepositoryProvider).watchTask(taskId);
});

final taskResponsesProvider = StreamProvider.family<List<TaskResponse>, String>((ref, taskId) {
  return ref.watch(taskResponseRepositoryProvider).watchTaskResponses(taskId);
});

final workerResponsesProvider = StreamProvider<List<TaskResponse>>((ref) {
  final userId = ref.watch(firebaseAuthProvider).currentUser?.uid;
  if (userId == null) {
    return Stream.value(const <TaskResponse>[]);
  }

  return ref.watch(taskResponseRepositoryProvider).watchResponsesByWorker(userId);
});

final taskMessagesProvider = StreamProvider.family<List<TaskMessage>, ({String taskId, String customerId, String workerId})>((ref, chatContext) {
  return ref.watch(messageRepositoryProvider).watchMessages(
        taskId: chatContext.taskId,
        customerId: chatContext.customerId,
        workerId: chatContext.workerId,
      );
});

final taskChatIdProvider = Provider.family<String, ({String taskId, String customerId, String workerId})>((ref, chatContext) {
  return taskChatId(
    taskId: chatContext.taskId,
    customerId: chatContext.customerId,
    workerId: chatContext.workerId,
  );
});

final userTaskRatingProvider = FutureProvider.family<TaskRating?, ({String taskId, String fromUserId})>((ref, request) {
  return ref.watch(ratingRepositoryProvider).fetchUserRatingForTask(
        taskId: request.taskId,
        fromUserId: request.fromUserId,
      );
});

final workerTaskLocationProvider = StreamProvider.family<WorkerTaskLocation?, String>((ref, taskId) {
  return ref.watch(workerLocationRepositoryProvider).watchTaskLocation(taskId);
});

final trustedWorkersProvider = StreamProvider<List<WorkerNetworkEntry>>((ref) {
  final userId = ref.watch(firebaseAuthProvider).currentUser?.uid;
  if (userId == null) {
    return Stream.value(const <WorkerNetworkEntry>[]);
  }

  return ref.watch(workerNetworkRepositoryProvider).watchTrustedWorkers(userId);
});

final referredWorkersProvider = StreamProvider<List<UserProfile>>((ref) {
  final userId = ref.watch(firebaseAuthProvider).currentUser?.uid;
  if (userId == null) {
    return Stream.value(const <UserProfile>[]);
  }

  return ref.watch(userProfileRepositoryProvider).watchReferredWorkers(userId);
});

final workerEarningsRecordsProvider = StreamProvider<List<EarningsRecord>>((ref) {
  final userId = ref.watch(firebaseAuthProvider).currentUser?.uid;
  if (userId == null) {
    return Stream.value(const <EarningsRecord>[]);
  }

  return ref.watch(earningsRecordRepositoryProvider).watchWorkerEarnings(userId);
});

final isWorkerTrustedProvider = StreamProvider.family<bool, ({String ownerUserId, String workerUserId})>((ref, request) {
  return ref.watch(workerNetworkRepositoryProvider).watchTrustedStatus(
        ownerUserId: request.ownerUserId,
        workerUserId: request.workerUserId,
      );
});

final userNotificationsProvider = StreamProvider<List<AppNotification>>((ref) {
  final userId = ref.watch(firebaseAuthProvider).currentUser?.uid;
  if (userId == null) {
    return Stream.value(const <AppNotification>[]);
  }

  return ref.watch(notificationRepositoryProvider).watchUserNotifications(userId);
});

final unreadNotificationCountProvider = Provider<int>((ref) {
  final notifications = ref.watch(userNotificationsProvider).valueOrNull ?? const <AppNotification>[];
  return notifications.where((notification) => !notification.read).length;
});
