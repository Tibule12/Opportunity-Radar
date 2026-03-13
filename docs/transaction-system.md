# Transaction System

## MVP Model

Opportunity Radar does not process or store real financial transactions during MVP.

- Customers and workers agree on a task price through the marketplace.
- The task lifecycle still moves through `open`, `matched`, `in_progress`, and `completed`.
- Payment is settled externally between the customer and worker.
- Supported real-world settlement examples include cash, bank transfer, mobile wallet payment, and direct peer-to-peer payment.

When a task is completed, the product surfaces this message:

> Payment should be settled directly between customer and worker as agreed.

## MVP Earnings Records

The platform stores estimated earnings records for worker reporting only.

Each earnings record contains:

- `worker_id`
- `customer_id`
- `task_id`
- `agreed_amount`
- `completed_at`
- `payment_settlement = external`

These records are used to support:

- Today earnings
- Weekly earnings
- Monthly earnings
- Lifetime completed work value

These values are informational and are not platform-processed payments.

## Completion Flow

1. Customer posts a task with a budget.
2. Workers respond and may negotiate.
3. Customer selects a worker.
4. Worker completes the task.
5. Task is marked completed.
6. An estimated earnings record is created for the worker.
7. Customer and worker settle payment externally.
8. Both users can submit ratings.

## Future Payment System

Phase 2 will introduce platform-managed payments.

See `docs/wallet-escrow-phase-2.md` for the proposed wallet, escrow, payout, and dispute contracts.

Planned capabilities:

- User wallets
- Pending balances
- Escrow for task funds
- Platform commission
- Secure payment-provider integration
- Dispute handling

### Planned Wallet Fields

- `user_id`
- `balance`
- `pending_balance`
- `transaction_history`

### Planned Escrow Flow

1. Customer selects a worker.
2. Customer deposits funds into platform escrow.
3. Platform holds funds until completion.
4. Customer confirms the task.
5. Platform releases the worker payout.
6. Platform retains a configurable service commission.

### Planned Disputes

Future versions may allow tasks to move into `disputed` status for manual review.

Administrators may review:

- Task details
- Chat history
- Location history
- Completion timeline

Administrators may then:

- Release funds to the worker
- Refund the customer
- Split the payment