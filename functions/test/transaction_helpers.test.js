const test = require('node:test');
const assert = require('node:assert/strict');
const {Timestamp} = require('firebase-admin/firestore');

const {
  buildEarningsRecord,
  externalPaymentCompletionMessage,
  externalPaymentSettlement,
  normalizeCurrencyCode,
  shouldGrantReferralReward,
} = require('../lib/transaction_helpers.js');

test('buildEarningsRecord creates a normalized informational ledger payload', () => {
  const completedAt = Timestamp.fromDate(new Date('2025-01-12T10:00:00.000Z'));
  const createdAt = Timestamp.fromDate(new Date('2025-01-12T10:05:00.000Z'));

  const record = buildEarningsRecord(
    'task_123',
    {
      assigned_worker_id: 'worker_1',
      created_by: 'customer_1',
      title: 'Install ceiling light',
      budget_amount: 850,
      currency: 'zar',
    },
    completedAt,
    createdAt,
  );

  assert.deepEqual(record, {
    worker_id: 'worker_1',
    customer_id: 'customer_1',
    task_id: 'task_123',
    task_title: 'Install ceiling light',
    agreed_amount: 850,
    currency: 'ZAR',
    payment_settlement: externalPaymentSettlement,
    completed_at: completedAt,
    created_at: createdAt,
  });
});

test('buildEarningsRecord falls back to default currency and null title when missing', () => {
  const completedAt = Timestamp.fromDate(new Date('2025-01-12T10:00:00.000Z'));
  const record = buildEarningsRecord('task_456', {}, completedAt, completedAt);

  assert.equal(record.currency, 'ZAR');
  assert.equal(record.task_title, null);
  assert.equal(record.payment_settlement, externalPaymentSettlement);
});

test('shouldGrantReferralReward only allows first completed-task reward', () => {
  assert.equal(shouldGrantReferralReward('referrer_1', null), true);
  assert.equal(shouldGrantReferralReward(' ', null), false);
  assert.equal(
    shouldGrantReferralReward('referrer_1', Timestamp.fromDate(new Date('2025-01-12T10:00:00.000Z'))),
    false,
  );
});

test('payment helper exports stable settlement copy and currency normalization', () => {
  assert.equal(externalPaymentCompletionMessage.includes('settled directly'), true);
  assert.equal(normalizeCurrencyCode(' usd '), 'USD');
  assert.equal(normalizeCurrencyCode(undefined), 'ZAR');
});