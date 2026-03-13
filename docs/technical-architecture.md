# Technical Architecture

## Stack

- Flutter mobile application
- Firebase Authentication for phone auth
- Cloud Firestore for primary realtime data
- Firebase Cloud Messaging for push notifications
- Firebase Storage for task photos and profile photos
- Firebase Cloud Functions for background workflows and matching logic
- Google Maps API for maps and geospatial display

## High-Level Architecture

### Client

Flutter app responsibilities:

- Authentication flows
- Profile management
- Task posting
- Feed and map rendering
- Response submission
- Chat interface
- Availability toggling
- Reverse geocoded location autofill
- Live worker location sharing for active tasks
- Ratings UI
- Push notification handling

### Backend

Firebase responsibilities:

- Identity management
- Realtime data sync
- File storage
- Push delivery
- Matching orchestration
- Cleanup of expired tasks
- Reputation aggregation

## Recommended Service Boundaries

### Firebase Authentication

- Phone number verification
- User identity bootstrap

### Firestore

- User profiles
- Tasks
- Task responses
- Chat messages
- Worker live locations for active tasks
- Ratings
- Notifications metadata
- Worker network relationships
- Device tokens on user documents for FCM fan-out

### Cloud Functions

Use functions for logic that should not rely on the client:

- On task creation, notify nearby available workers in waves
- On response creation, notify task owner
- On task status changes, update related documents
- On rating creation, recompute aggregate profile scores
- On expiration, mark tasks expired and stop notifications
- Future: downsample or fan out live location updates if tracking load grows

### Firebase Storage

- Profile photos
- Task photos

### Firebase Cloud Messaging

- New task alerts
- New response alerts
- New message alerts
- Task status alerts
- Trusted-worker-first task delivery
- Future: worker live-location status alerts where needed

## Suggested Flutter App Structure

```text
lib/
  app/
    routing/
    theme/
    config/
  core/
    constants/
    errors/
    services/
    utils/
  features/
    auth/
    profile/
    tasks/
    feed/
    map/
    chat/
    ratings/
    notifications/
    dashboard/
  shared/
    widgets/
    models/
```

## State Management

Recommended options:

- Riverpod for scalable app state
- Bloc if the team prefers event-driven structure

Riverpod is a strong fit because the app needs reactive data flows, good testability, and modular feature boundaries.

## Geolocation Strategy

Firestore is not a geospatial engine by itself, so location matching should be kept simple in MVP.

Recommended MVP approach:

- Store latitude and longitude on task and user documents
- Store a geohash for basic proximity queries
- Use client-side distance calculation for final sorting
- Use Cloud Functions to expand search radius when necessary
- Use platform geocoding for human-readable addresses when device coordinates are captured
- Keep live worker location in a dedicated collection scoped to matched or active tasks

If scale increases later, evaluate a specialized search layer or geospatial indexing service.

## Security Model

### Principles

- Users can read only the data necessary for active tasks and chats
- A user may only edit their own profile
- Only task creators can update task ownership decisions
- Only involved participants can access a task chat
- Ratings are restricted to users involved in a completed task

### Recommended Guardrails

- Validate all ownership and role checks in Firestore rules
- Put sensitive matching logic in Cloud Functions
- Avoid letting clients write aggregate reputation fields directly
- Record server timestamps for critical events

## Realtime Flows

### Task Creation Flow

1. Customer posts task.
2. Task document is created with status open.
3. Cloud Function identifies available workers in range.
4. Notifications are sent in waves.
5. Workers receive live feed update and push alert.

### Worker Response Flow

1. Worker submits response.
2. Response document is created.
3. Customer receives push notification.
4. Customer compares responses.
5. Customer selects a worker and task moves to matched.

### Completion Flow

1. Task is marked completed.
2. Rating prompts are enabled.
3. Both parties submit ratings.
4. Aggregate profile metrics are recalculated.

### Active Task Tracking Flow

1. Customer selects a worker and task moves to matched.
2. Assigned worker can start live location sharing.
3. Worker location writes are stored under a task-scoped live location document.
4. Customer sees the latest worker position in task detail.
5. Tracking stops when the worker stops sharing or the task ends.

## Observability

Track at minimum:

- Notification delivery attempts
- Task response latency
- Match rate by radius band
- Task completion funnel
- User activation and retention

## Immediate Build Recommendation

The next practical step is local platform setup and real-device validation for Maps, geolocator, geocoding, live worker tracking, and FCM token registration since the code paths are now present but the workspace still lacks generated mobile platform folders.