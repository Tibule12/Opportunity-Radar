import {Timestamp} from 'firebase-admin/firestore';

export const externalPaymentSettlement = 'external';
export const externalPaymentCompletionMessage =
  'Payment should be settled directly between customer and worker as agreed.';

function asNonEmptyString(value: unknown): string | null {
  if (typeof value !== 'string') {
    return null;
  }

  const trimmed = value.trim();
  return trimmed.length > 0 ? trimmed : null;
}

export function normalizeCurrencyCode(value: unknown): string {
  return asNonEmptyString(value)?.toUpperCase() ?? 'ZAR';
}

export function shouldGrantReferralReward(
  referredBy: unknown,
  referralFirstTaskRewardedAt: unknown,
): boolean {
  return asNonEmptyString(referredBy) != null && !(referralFirstTaskRewardedAt instanceof Timestamp);
}

export function buildEarningsRecord(
  taskId: string,
  task: Record<string, unknown>,
  completedAt: Timestamp,
  createdAt: Timestamp = Timestamp.now(),
): Record<string, unknown> {
  return {
    worker_id: typeof task.assigned_worker_id === 'string' ? task.assigned_worker_id : '',
    customer_id: typeof task.created_by === 'string' ? task.created_by : '',
    task_id: taskId,
    task_title: asNonEmptyString(task.title),
    agreed_amount: typeof task.budget_amount === 'number' ? task.budget_amount : 0,
    currency: normalizeCurrencyCode(task.currency),
    payment_settlement: externalPaymentSettlement,
    completed_at: completedAt,
    created_at: createdAt,
  };
}