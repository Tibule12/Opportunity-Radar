# Data Model

## Collections Overview

- users
- tasks
- task_responses
- messages
- ratings
- worker_networks
- notifications

## users

Document ID: auth uid

Suggested fields:

```json
{
  "display_name": "Sipho Dlamini",
  "phone_number": "+27...",
  "photo_url": "https://...",
  "roles": ["customer", "worker"],
  "availability_status": "available",
  "rating_average": 4.9,
  "rating_count": 24,
  "completed_task_count": 18,
  "verification_status": "verified",
  "response_speed_seconds": 95,
  "trust_badges": ["fast_responder"],
  "device_tokens": ["fcm_token_1"],
  "location": {
    "lat": -26.1076,
    "lng": 28.0567,
    "geohash": "..."
  },
  "trusted_worker_ids": ["uid_123"],
  "referred_by": "uid_456",
  "created_at": "server_timestamp",
  "updated_at": "server_timestamp"
}
```

## tasks

Document ID: generated id

Suggested fields:

```json
{
  "title": "Deliver parcel",
  "description": "Pick up parcel and deliver to office",
  "category": "delivery",
  "budget_amount": 80,
  "currency": "ZAR",
  "status": "open",
  "created_by": "customer_uid",
  "assigned_worker_id": null,
  "location": {
    "address_text": "Sandton City",
    "lat": -26.1076,
    "lng": 28.0567,
    "geohash": "..."
  },
  "photo_urls": [],
  "notified_radius_meters": 500,
  "response_count": 0,
  "view_count": 0,
  "expires_at": "timestamp",
  "created_at": "server_timestamp",
  "updated_at": "server_timestamp"
}
```

## task_responses

Document ID: generated id

Suggested fields:

```json
{
  "task_id": "task_123",
  "worker_id": "worker_uid",
  "customer_id": "customer_uid",
  "message": "I can do this now",
  "offered_amount": 110,
  "estimated_arrival_minutes": 7,
  "status": "pending",
  "created_at": "server_timestamp",
  "updated_at": "server_timestamp"
}
```

Response status values:

- pending
- shortlisted
- accepted
- declined
- withdrawn

## messages

Document ID: generated id

Suggested fields:

```json
{
  "task_id": "task_123",
  "chat_id": "task_123_customer_uid_worker_uid",
  "sender_id": "worker_uid",
  "recipient_id": "customer_uid",
  "message_type": "text",
  "text": "I will arrive in 5 minutes",
  "location_payload": null,
  "offer_payload": null,
  "created_at": "server_timestamp",
  "read_at": null
}
```

Message type values:

- text
- location
- offer
- system

## ratings

Document ID: generated id

Suggested fields:

```json
{
  "task_id": "task_123",
  "from_user_id": "customer_uid",
  "to_user_id": "worker_uid",
  "reliability": 5,
  "communication": 4,
  "speed": 5,
  "professionalism": 5,
  "comment": "Fast and reliable",
  "created_at": "server_timestamp"
}
```

## worker_networks

This collection tracks referrals and trusted worker relationships.

Suggested document id:

- `{owner_user_id}_{worker_user_id}`

Suggested fields:

```json
{
  "owner_user_id": "customer_uid",
  "worker_user_id": "worker_uid",
  "relationship_type": "trusted",
  "created_at": "server_timestamp"
}
```

Relationship type values:

- trusted
- referred

## notifications

This collection stores notification history or delivery metadata for auditing and in-app displays.

These documents are now paired with device-token-based FCM fan-out when the user profile contains active `device_tokens`.

Suggested fields:

```json
{
  "user_id": "worker_uid",
  "type": "new_task",
  "title": "New opportunity nearby",
  "body": "Deliver parcel - R80 - 600m away",
  "task_id": "task_123",
  "read": false,
  "created_at": "server_timestamp"
}
```

## Indexing Recommendations

Create indexes for:

- tasks by status, category, created_at
- tasks by status and geohash band
- task_responses by task_id and created_at
- messages by chat_id and created_at
- ratings by to_user_id and created_at
- notifications by user_id and created_at

## Aggregates To Compute Server-Side

- user rating_average
- user rating_count
- user completed_task_count
- user response_speed_seconds
- task response_count
- task view_count

## Data Integrity Rules

- Only the task creator can assign a worker.
- Only the assigned worker and task creator can mark progress states.
- Ratings require a completed task relationship.
- Users must not directly edit aggregate metrics.