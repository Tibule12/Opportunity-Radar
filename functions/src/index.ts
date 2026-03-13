import {onDocumentCreated, onDocumentUpdated} from 'firebase-functions/v2/firestore';
import {onSchedule} from 'firebase-functions/v2/scheduler';
import * as logger from 'firebase-functions/logger';
import {initializeApp} from 'firebase-admin/app';
import {FieldValue, getFirestore, Timestamp} from 'firebase-admin/firestore';
import {getMessaging} from 'firebase-admin/messaging';

import {
  buildEarningsRecord,
  externalPaymentCompletionMessage,
  shouldGrantReferralReward,
} from './transaction_helpers.js';

initializeApp();

const db = getFirestore();
const messaging = getMessaging();
const maxInitialWorkerNotifications = 25;
const distributionWaves = [
  {stage: 'initial', radiusMeters: 500},
  {stage: 'expanded_local', radiusMeters: 1500},
  {stage: 'expanded_city', radiusMeters: 5000},
];
const referralRewardPoints = 100;

type MarketplaceNotificationInput = {
  userIds: string[];
  type: string;
  title: string;
  body: string;
  taskId?: string;
};

type EligibleWorker = {
  userId: string;
  distance: number;
  isTrusted: boolean;
};

type WorkerDispatchResult = {
  count: number;
  trustedCount: number;
  recipientIds: string[];
  radiusMeters: number;
  stage: string;
};

function toRadians(value: number): number {
  return value * (Math.PI / 180);
}

function distanceMeters(
  fromLat: number,
  fromLng: number,
  toLat: number,
  toLng: number,
): number {
  const earthRadiusMeters = 6371000;
  const dLat = toRadians(toLat - fromLat);
  const dLng = toRadians(toLng - fromLng);
  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(toRadians(fromLat)) *
      Math.cos(toRadians(toLat)) *
      Math.sin(dLng / 2) *
      Math.sin(dLng / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));

  return earthRadiusMeters * c;
}

async function createNotification(input: {
  userId: string;
  type: string;
  title: string;
  body: string;
  taskId?: string;
}): Promise<void> {
  await db.collection('notifications').add({
    user_id: input.userId,
    type: input.type,
    title: input.title,
    body: input.body,
    task_id: input.taskId ?? null,
    read: false,
    read_at: null,
    created_at: Timestamp.now(),
  });
}

async function sendPushNotifications(input: MarketplaceNotificationInput): Promise<void> {
  const userIds = [...new Set(input.userIds.filter((userId) => userId.trim().length > 0))];
  if (userIds.length === 0) {
    return;
  }

  const userSnapshots = await Promise.all(
    userIds.map((userId) => db.collection('users').doc(userId).get()),
  );
  const tokens = userSnapshots.flatMap((snapshot) => {
    const user = snapshot.data();
    const deviceTokens = user?.device_tokens;
    if (!Array.isArray(deviceTokens)) {
      return [];
    }

    return deviceTokens.filter(
      (token): token is string => typeof token === 'string' && token.trim().length > 0,
    );
  });

  if (tokens.length === 0) {
    return;
  }

  const batches: string[][] = [];
  for (let index = 0; index < tokens.length; index += 500) {
    batches.push(tokens.slice(index, index + 500));
  }

  await Promise.all(
    batches.map(async (batch) => {
      const result = await messaging.sendEachForMulticast({
        tokens: batch,
        notification: {
          title: input.title,
          body: input.body,
        },
        data: {
          type: input.type,
          taskId: input.taskId ?? '',
          route: input.taskId ? `/tasks/${input.taskId}` : '/notifications',
        },
      });

      if (result.failureCount > 0) {
        logger.warn('Push delivery had token-level failures.', {
          attempted: batch.length,
          failures: result.failureCount,
        });
      }
    }),
  );
}

async function notifyUsers(input: MarketplaceNotificationInput): Promise<void> {
  const userIds = [...new Set(input.userIds.filter((userId) => userId.trim().length > 0))];
  if (userIds.length === 0) {
    return;
  }

  await Promise.all(userIds.map((userId) => createNotification({
    userId,
    type: input.type,
    title: input.title,
    body: input.body,
    taskId: input.taskId,
  })));
  await sendPushNotifications(input);
}

function normalizeWorkerStatus(user: Record<string, unknown>): string {
  const explicitStatus = typeof user.worker_status === 'string' ? user.worker_status : '';
  if (explicitStatus === 'online' || explicitStatus === 'busy' || explicitStatus === 'offline') {
    return explicitStatus;
  }

  const availabilityStatus = typeof user.availability_status === 'string'
    ? user.availability_status
    : '';
  if (availabilityStatus === 'available') {
    return 'online';
  }

  if (availabilityStatus === 'busy' || availabilityStatus === 'offline') {
    return availabilityStatus;
  }

  return 'offline';
}

function budgetLabel(task: Record<string, unknown>): string {
  const amount = typeof task.budget_amount === 'number' ? task.budget_amount : 0;
  const currency = typeof task.currency === 'string' && task.currency.trim().length > 0
    ? task.currency.trim().toUpperCase()
    : 'ZAR';
  return `${currency} ${amount.toFixed(0)}`;
}

function taskAddress(task: Record<string, unknown>): string {
  const location = (task.location ?? {}) as Record<string, unknown>;
  return typeof location.address_text === 'string' && location.address_text.trim().length > 0
    ? location.address_text.trim()
    : 'your area';
}

function getCurrentDistributionWave(task: Record<string, unknown>): {stage: string; radiusMeters: number} {
  const currentStage = typeof task.distribution_stage === 'string'
    ? task.distribution_stage
    : distributionWaves[0].stage;
  const matchedWave = distributionWaves.find((wave) => wave.stage === currentStage);
  return matchedWave ?? distributionWaves[0];
}

function getNextDistributionWave(task: Record<string, unknown>): {stage: string; radiusMeters: number} | null {
  const currentWave = getCurrentDistributionWave(task);
  const currentIndex = distributionWaves.findIndex((wave) => wave.stage === currentWave.stage);
  if (currentIndex < 0 || currentIndex >= distributionWaves.length - 1) {
    return null;
  }

  return distributionWaves[currentIndex + 1];
}

async function notifyEligibleWorkersForTask(
  taskId: string,
  task: Record<string, unknown>,
  options?: {
    radiusMeters?: number;
    stage?: string;
  },
): Promise<WorkerDispatchResult> {
  const taskCreator = typeof task.created_by === 'string' ? task.created_by : '';
  const trustedWorkersSnapshot = taskCreator.trim().length === 0
    ? null
    : await db
        .collection('worker_networks')
        .where('owner_user_id', '==', taskCreator)
        .where('relationship_type', '==', 'trusted')
        .get();
  const workersSnapshot = await db
    .collection('users')
    .where('roles', 'array-contains', 'worker')
    .get();
  const trustedWorkerIds = new Set(
    (trustedWorkersSnapshot?.docs ?? []).map((doc) => doc.get('worker_user_id') as string),
  );
  const alreadyNotifiedWorkerIds = new Set(
    Array.isArray(task.notified_worker_ids)
      ? task.notified_worker_ids.filter(
          (value): value is string => typeof value === 'string' && value.trim().length > 0,
        )
      : [],
  );

  const taskLocation = (task.location ?? {}) as Record<string, unknown>;
  const taskLat = typeof taskLocation.lat === 'number' ? taskLocation.lat : null;
  const taskLng = typeof taskLocation.lng === 'number' ? taskLocation.lng : null;
  const taskRadiusMeters = options?.radiusMeters ??
    (typeof task.notified_radius_meters === 'number' ? task.notified_radius_meters : 500);
  const stage = options?.stage ??
    (typeof task.distribution_stage === 'string' ? task.distribution_stage : 'initial');

  const eligibleWorkers = workersSnapshot.docs
    .map((doc) => {
      const worker = doc.data();
      if (doc.id === task.created_by || normalizeWorkerStatus(worker) !== 'online') {
        return null;
      }

      if (alreadyNotifiedWorkerIds.has(doc.id)) {
        return null;
      }

      const workerLocation = (worker.location ?? {}) as Record<string, unknown>;
      const workerLat = typeof workerLocation.lat === 'number' ? workerLocation.lat : null;
      const workerLng = typeof workerLocation.lng === 'number' ? workerLocation.lng : null;

      if (taskLat == null || taskLng == null || workerLat == null || workerLng == null) {
        return {userId: doc.id, distance: Number.MAX_SAFE_INTEGER};
      }

      const distance = distanceMeters(taskLat, taskLng, workerLat, workerLng);
      if (distance > taskRadiusMeters) {
        return null;
      }

      return {userId: doc.id, distance, isTrusted: trustedWorkerIds.has(doc.id)};
    })
    .filter((worker): worker is {userId: string; distance: number; isTrusted: boolean} => worker != null)
    .sort((left, right) => {
      if (left.isTrusted != right.isTrusted) {
        return left.isTrusted ? -1 : 1;
      }

      return left.distance - right.distance;
    })
    .slice(0, maxInitialWorkerNotifications);

  await notifyUsers({
    userIds: eligibleWorkers.map((worker) => worker.userId),
    type: 'new_task',
    title: 'New opportunity nearby',
    body: `${task.title ?? 'A new task'} • ${budgetLabel(task)} • ${taskAddress(task)}`,
    taskId,
  });

  await db.collection('tasks').doc(taskId).set({
    workers_notified: FieldValue.increment(eligibleWorkers.length),
    distribution_stage: stage,
    notified_radius_meters: taskRadiusMeters,
    last_distribution_at: Timestamp.now(),
    ...(eligibleWorkers.length > 0
      ? {notified_worker_ids: FieldValue.arrayUnion(...eligibleWorkers.map((worker) => worker.userId))}
      : {}),
    updated_at: Timestamp.now(),
  }, {merge: true});

  return {
    count: eligibleWorkers.length,
    trustedCount: eligibleWorkers.filter((worker) => worker.isTrusted).length,
    recipientIds: eligibleWorkers.map((worker) => worker.userId),
    radiusMeters: taskRadiusMeters,
    stage,
  };
}

async function setWorkerStatus(userId: string, workerStatus: 'online' | 'busy' | 'offline'): Promise<void> {
  if (userId.trim().length === 0) {
    return;
  }

  await db.collection('users').doc(userId).set({
    worker_status: workerStatus,
    availability_status: workerStatus === 'online' ? 'available' : workerStatus,
    updated_at: Timestamp.now(),
  }, {merge: true});
}

async function applyCompletionRewards(taskId: string, task: Record<string, unknown>): Promise<void> {
  const workerId = typeof task.assigned_worker_id === 'string' ? task.assigned_worker_id : '';
  const customerId = typeof task.created_by === 'string' ? task.created_by : '';
  if (workerId.trim().length === 0) {
    return;
  }

  const payout = typeof task.budget_amount === 'number' ? task.budget_amount : 0;
  const completedAt = task.completed_at instanceof Timestamp ? task.completed_at : Timestamp.now();
  const earningsRef = db.collection('earnings_records').doc(taskId);
  const workerRef = db.collection('users').doc(workerId);
  const customerRef = customerId.trim().length === 0 ? null : db.collection('users').doc(customerId);

  let rewardGrantedTo = '';
  await db.runTransaction(async (transaction) => {
    const earningsSnapshot = await transaction.get(earningsRef);
    if (earningsSnapshot.exists) {
      return;
    }

    const workerSnapshot = await transaction.get(workerRef);
    const worker = workerSnapshot.data() ?? {};
    const referredBy = typeof worker.referred_by === 'string' ? worker.referred_by : '';
    const alreadyRewarded = worker.referral_first_task_rewarded_at instanceof Timestamp;

    transaction.set(earningsRef, {
      ...buildEarningsRecord(taskId, task, completedAt, Timestamp.now()),
    });
    transaction.set(workerRef, {
      earnings_today: FieldValue.increment(payout),
      earnings_week: FieldValue.increment(payout),
      earnings_month: FieldValue.increment(payout),
      earnings_lifetime: FieldValue.increment(payout),
      completed_task_count: FieldValue.increment(1),
      updated_at: Timestamp.now(),
    }, {merge: true});

    if (customerRef != null) {
      transaction.set(customerRef, {
        completed_task_count: FieldValue.increment(1),
        updated_at: Timestamp.now(),
      }, {merge: true});
    }

    if (shouldGrantReferralReward(referredBy, worker.referral_first_task_rewarded_at)) {
      transaction.set(workerRef, {
        referral_first_task_rewarded_at: Timestamp.now(),
        updated_at: Timestamp.now(),
      }, {merge: true});
      transaction.set(db.collection('users').doc(referredBy), {
        referral_count: FieldValue.increment(1),
        reward_points: FieldValue.increment(referralRewardPoints),
        updated_at: Timestamp.now(),
      }, {merge: true});
      rewardGrantedTo = referredBy;
    }
  });

  if (rewardGrantedTo.trim().length === 0) {
    return;
  }

  await notifyUsers({
    userIds: [rewardGrantedTo],
    type: 'referral_reward',
    title: 'Referral reward unlocked',
    body: `One of your referred workers completed their first task. You earned ${referralRewardPoints} points.`,
    taskId,
  });
}

export const onTaskCreated = onDocumentCreated('tasks/{taskId}', async (event) => {
  const snapshot = event.data;
  if (!snapshot) {
    logger.warn('Missing task snapshot on create event.');
    return;
  }

  const task = snapshot.data();
  logger.info('Task created, matching workflow placeholder started.', {
    taskId: snapshot.id,
    category: task.category,
    budget: task.budget_amount,
  });

  const initialWave = distributionWaves[0];
  const notifiedWorkers = await notifyEligibleWorkersForTask(snapshot.id, task, {
    radiusMeters: initialWave.radiusMeters,
    stage: initialWave.stage,
  });

  await notifyUsers({
    userIds: [task.created_by],
    type: 'system',
    title: 'Task received',
    body: notifiedWorkers.count > 0
      ? notifiedWorkers.trustedCount > 0
        ? `Your task is live. ${notifiedWorkers.trustedCount} trusted workers and ${notifiedWorkers.count - notifiedWorkers.trustedCount} nearby workers were notified.`
        : `Your task is live and ${notifiedWorkers.count} nearby workers were notified.`
      : 'Your task is live. No nearby online workers were found yet.',
    taskId: snapshot.id,
  });
});

export const onTaskResponseCreated = onDocumentCreated(
  'task_responses/{responseId}',
  async (event) => {
    const snapshot = event.data;
    if (!snapshot) {
      logger.warn('Missing task response snapshot on create event.');
      return;
    }

    const response = snapshot.data();
    logger.info('New task response received.', {
      responseId: snapshot.id,
      taskId: response.task_id,
      workerId: response.worker_id,
    });

    await db.collection('tasks').doc(response.task_id).update({
      response_count: FieldValue.increment(1),
      responses_received: FieldValue.increment(1),
      distribution_stage: 'responses_started',
      updated_at: Timestamp.now(),
    });

    await notifyUsers({
      userIds: [response.customer_id],
      type: 'task_response',
      title: 'New worker response',
      body: response.message ?? 'A worker has responded to your task.',
      taskId: response.task_id,
    });
  },
);

export const onTaskResponseNotification = onDocumentUpdated(
  'task_responses/{responseId}',
  async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();

    if (!before || !after || before.status == after.status) {
      return;
    }

    if (after.status === 'accepted') {
      await notifyUsers({
        userIds: [after.worker_id],
        type: 'task_selected',
        title: 'You were selected',
        body: 'A customer selected you for a task. Open the app to coordinate details.',
        taskId: after.task_id,
      });

      await db.collection('messages').add({
        task_id: after.task_id,
        chat_id: `${after.task_id}_${after.customer_id}_${after.worker_id}`,
        sender_id: after.customer_id,
        recipient_id: after.worker_id,
        message_type: 'system',
        text: 'You have been selected for this task. Use this chat to confirm the final details.',
        location_payload: null,
        offer_payload: null,
        created_at: Timestamp.now(),
        read_at: null,
      });
    }
  },
);

export const onMessageCreated = onDocumentCreated('messages/{messageId}', async (event) => {
  const snapshot = event.data;
  if (!snapshot) {
    logger.warn('Missing message snapshot on create event.');
    return;
  }

  const message = snapshot.data();
  if (message.message_type === 'system') {
    return;
  }

  await notifyUsers({
    userIds: [message.recipient_id],
    type: 'task_message',
    title: 'New task message',
    body: message.text ?? 'You have a new task message.',
    taskId: message.task_id,
  });
});

export const onTaskUpdated = onDocumentUpdated('tasks/{taskId}', async (event) => {
  const before = event.data?.before.data();
  const after = event.data?.after.data();

  if (!before || !after) {
    return;
  }

  const statusChanged = before.status !== after.status;
  const assignedWorkerChanged = before.assigned_worker_id !== after.assigned_worker_id;
  const assignedWorkerId = typeof after.assigned_worker_id === 'string' ? after.assigned_worker_id : '';

  if (!statusChanged && !assignedWorkerChanged) {
    return;
  }

  if (assignedWorkerChanged && typeof before.assigned_worker_id === 'string' && before.assigned_worker_id) {
    await setWorkerStatus(before.assigned_worker_id, 'online');
  }

  if ((after.status === 'matched' || after.status === 'in_progress') && assignedWorkerId) {
    await setWorkerStatus(assignedWorkerId, 'busy');
  }

  if (after.status === 'in_progress' && assignedWorkerId && statusChanged) {
    await notifyUsers({
      userIds: [after.created_by, assignedWorkerId],
      type: 'task_in_progress',
      title: 'Task is in progress',
      body: 'Your matched task has moved into progress.',
      taskId: event.params.taskId,
    });
  }

  if (after.status === 'completed' && assignedWorkerId && statusChanged) {
    await setWorkerStatus(assignedWorkerId, 'online');
    await applyCompletionRewards(event.params.taskId, after);
    await notifyUsers({
      userIds: [after.created_by, assignedWorkerId],
      type: 'task_completed',
      title: 'Task completed',
      body: `This task was marked completed. ${externalPaymentCompletionMessage}`,
      taskId: event.params.taskId,
    });
  }

  if (after.status === 'expired' && assignedWorkerId && statusChanged) {
    await setWorkerStatus(assignedWorkerId, 'online');
  }
});

export const expandOpenTaskDistribution = onSchedule('every 5 minutes', async () => {
  const now = Timestamp.now();
  const openTasks = await db
    .collection('tasks')
    .where('status', '==', 'open')
    .where('expires_at', '>', now)
    .get();

  if (openTasks.empty) {
    logger.info('No open tasks require distribution expansion.');
    return;
  }

  for (const doc of openTasks.docs) {
    const task = doc.data();
    const responsesReceived = typeof task.responses_received === 'number'
      ? task.responses_received
      : typeof task.response_count === 'number'
        ? task.response_count
        : 0;

    if (responsesReceived > 0 || typeof task.assigned_worker_id === 'string') {
      continue;
    }

    const nextWave = getNextDistributionWave(task);
    if (!nextWave) {
      continue;
    }

    const createdAt = task.created_at instanceof Timestamp ? task.created_at : now;
    const ageMinutes = (now.toMillis() - createdAt.toMillis()) / 60000;
    const minimumAge = nextWave.stage === 'expanded_local' ? 5 : 15;
    if (ageMinutes < minimumAge) {
      continue;
    }

    const dispatch = await notifyEligibleWorkersForTask(doc.id, task, {
      radiusMeters: nextWave.radiusMeters,
      stage: nextWave.stage,
    });

    if (dispatch.count > 0 && typeof task.created_by === 'string') {
      await notifyUsers({
        userIds: [task.created_by],
        type: 'distribution_expanded',
        title: 'Still searching',
        body: `No responses yet, so Opportunity Radar widened the search and alerted ${dispatch.count} more workers.`,
        taskId: doc.id,
      });
    }
  }
});

export const notifyExpiringOpenTasks = onSchedule('every 5 minutes', async () => {
  const now = Timestamp.now();
  const threshold = Timestamp.fromMillis(now.toMillis() + 10 * 60 * 1000);
  const expiringTasks = await db
    .collection('tasks')
    .where('status', '==', 'open')
    .where('expires_at', '>', now)
    .where('expires_at', '<=', threshold)
    .get();

  if (expiringTasks.empty) {
    logger.info('No open tasks require expiry nudges.');
    return;
  }

  for (const doc of expiringTasks.docs) {
    const task = doc.data();
    if (task.expiry_warning_sent_at instanceof Timestamp) {
      continue;
    }

    if (typeof task.created_by === 'string') {
      await notifyUsers({
        userIds: [task.created_by],
        type: 'task_urgency',
        title: 'Task expires soon',
        body: `${task.title ?? 'Your task'} has less than 10 minutes left. Repost or widen the search if you still need help.`,
        taskId: doc.id,
      });
    }

    await doc.ref.set({
      expiry_warning_sent_at: now,
      updated_at: now,
    }, {merge: true});
  }
});

export const onRatingCreated = onDocumentCreated('ratings/{ratingId}', async (event) => {
  const snapshot = event.data;
  if (!snapshot) {
    logger.warn('Missing rating snapshot on create event.');
    return;
  }

  const rating = snapshot.data();
  const ratingsSnapshot = await db
    .collection('ratings')
    .where('to_user_id', '==', rating.to_user_id)
    .get();

  let totalScore = 0;
  for (const doc of ratingsSnapshot.docs) {
    const data = doc.data();
    totalScore +=
      ((data.reliability ?? 0) +
          (data.communication ?? 0) +
          (data.speed ?? 0) +
          (data.professionalism ?? 0)) /
      4;
  }

  const ratingCount = ratingsSnapshot.size;
  const ratingAverage = ratingCount == 0 ? 0 : totalScore / ratingCount;

  await db.collection('users').doc(rating.to_user_id).set({
    rating_average: Number(ratingAverage.toFixed(2)),
    rating_count: ratingCount,
    updated_at: Timestamp.now(),
  }, {merge: true});
});

export const expireOpenTasks = onSchedule('every 10 minutes', async () => {
  const now = Timestamp.now();
  const expiredTasks = await db
    .collection('tasks')
    .where('status', '==', 'open')
    .where('expires_at', '<=', now)
    .get();

  if (expiredTasks.empty) {
    logger.info('No open tasks require expiration.');
    return;
  }

  const batch = db.batch();
  const expiredTaskOwners: Array<{userId: string; taskId: string; title: string}> = [];

  for (const doc of expiredTasks.docs) {
    const task = doc.data();
    batch.update(doc.ref, {
      status: 'expired',
      updated_at: now,
    });
    expiredTaskOwners.push({
      userId: task.created_by as string,
      taskId: doc.id,
      title: (task.title as string | undefined) ?? 'Your task',
    });
  }

  await batch.commit();
  await Promise.all(expiredTaskOwners.map((entry) => notifyUsers({
    userIds: [entry.userId],
    type: 'task_expired',
    title: 'Task expired',
    body: `${entry.title} expired before a final match was made.`,
    taskId: entry.taskId,
  })));
  logger.info('Expired stale open tasks.', {count: expiredTasks.size});
});
