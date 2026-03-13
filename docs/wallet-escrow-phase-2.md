# Wallet And Escrow Phase 2 Contracts

This document defines the concrete data contracts for a future platform-managed payment system.

The current MVP remains external-settlement only. Nothing in this document is active yet.

## Design Goals

- Keep customer funds segregated from worker balances.
- Preserve a complete immutable ledger for every balance movement.
- Support partial refunds, dispute holds, and platform commission.
- Make payout state machine transitions explicit and auditable.

## Collections

### `wallets`

One wallet per user.

```json
{
  "user_id": "user_123",
  "currency": "ZAR",
  "available_balance": 0,
  "pending_balance": 0,
  "held_balance": 0,
  "lifetime_inflow": 0,
  "lifetime_outflow": 0,
  "last_transaction_at": "timestamp",
  "created_at": "timestamp",
  "updated_at": "timestamp"
}
```

Rules:

- `available_balance` is withdrawable or reusable.
- `pending_balance` is credited but not yet cleared for payout.
- `held_balance` is locked by escrow or dispute action.
- Only backend code mutates wallet balances.

### `wallet_transactions`

Immutable ledger entries for every balance movement.

```json
{
  "wallet_id": "wallet_user_123",
  "user_id": "user_123",
  "task_id": "task_123",
  "escrow_id": "escrow_123",
  "type": "escrow_hold",
  "direction": "debit",
  "amount": 450,
  "currency": "ZAR",
  "balance_bucket": "available_balance",
  "reference": "paystack_charge_123",
  "metadata": {
    "commission_amount": 45,
    "reason": "customer funded task"
  },
  "created_at": "timestamp"
}
```

Allowed `type` values:

- `deposit`
- `withdrawal`
- `escrow_hold`
- `escrow_release`
- `escrow_refund`
- `commission_capture`
- `adjustment_credit`
- `adjustment_debit`
- `dispute_hold`
- `dispute_release`

### `escrows`

One escrow per funded task instance.

```json
{
  "task_id": "task_123",
  "customer_id": "customer_1",
  "worker_id": "worker_1",
  "status": "funded",
  "currency": "ZAR",
  "task_amount": 450,
  "platform_fee_amount": 45,
  "worker_payout_amount": 405,
  "funded_at": "timestamp",
  "released_at": null,
  "refunded_at": null,
  "disputed_at": null,
  "payment_provider": "paystack",
  "payment_reference": "charge_123",
  "created_at": "timestamp",
  "updated_at": "timestamp"
}
```

Allowed `status` values:

- `pending_funding`
- `funded`
- `released`
- `partially_refunded`
- `refunded`
- `disputed`
- `cancelled`

### `payouts`

Tracks worker withdrawals or external transfers.

```json
{
  "worker_id": "worker_1",
  "wallet_id": "wallet_worker_1",
  "amount": 405,
  "currency": "ZAR",
  "status": "queued",
  "provider": "paystack_transfer",
  "provider_reference": null,
  "failure_reason": null,
  "requested_at": "timestamp",
  "processed_at": null,
  "created_at": "timestamp",
  "updated_at": "timestamp"
}
```

Allowed `status` values:

- `queued`
- `processing`
- `paid`
- `failed`
- `reversed`

### `disputes`

Structured payment/task dispute cases.

```json
{
  "task_id": "task_123",
  "escrow_id": "escrow_123",
  "opened_by": "customer_1",
  "customer_id": "customer_1",
  "worker_id": "worker_1",
  "status": "open",
  "reason_code": "quality_issue",
  "summary": "Customer says the installation failed after one hour.",
  "evidence_refs": ["message_123", "photo_1"],
  "resolution": null,
  "opened_at": "timestamp",
  "resolved_at": null,
  "created_at": "timestamp",
  "updated_at": "timestamp"
}
```

Allowed `status` values:

- `open`
- `under_review`
- `resolved_customer`
- `resolved_worker`
- `split_resolution`
- `dismissed`

## State Machine

### Funding

1. Task moves from `matched` to `awaiting_funding`.
2. Customer completes provider payment.
3. Backend creates an `escrows` record with `status = funded`.
4. Backend creates wallet transactions to reflect customer debit and escrow hold.
5. Task moves to `funded` or `in_progress` depending on product policy.

### Completion

1. Worker marks task complete.
2. Customer confirms completion or auto-release timer expires.
3. Backend sets escrow to `released`.
4. Backend writes wallet transactions for worker payout and commission capture.
5. Worker wallet moves funds from `pending_balance` to `available_balance` when clearing rules are met.

### Refunds And Disputes

1. A dispute or cancellation freezes escrow funds.
2. Backend sets `escrows.status = disputed` or `cancelled`.
3. Backend records a `disputes` case if needed.
4. Resolution writes one or more wallet transactions:
   - full refund to customer
   - full release to worker
   - split resolution across both parties

## Backend Ownership

The following fields should be server-managed only:

- All wallet balance fields
- All escrow status fields
- All payout status fields
- All dispute resolution fields
- All transaction ledger rows

## Migration Path From MVP

- Keep `earnings_records` as a reporting view for completed work value.
- Introduce wallets and escrow without deleting historical MVP earnings data.
- Backfill `earnings_records` into wallet analytics only if needed for reporting.
- Gate platform-managed payments behind a feature flag and provider rollout plan.