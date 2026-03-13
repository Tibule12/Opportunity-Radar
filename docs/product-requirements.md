# Product Requirements

## Product Summary

Opportunity Radar is a mobile marketplace for real-time, location-based physical tasks. Customers post tasks, nearby workers respond, both parties negotiate through chat, and the platform captures reputation after task completion.

## Product Goals

1. Help customers find nearby help within minutes.
2. Help workers discover local earning opportunities in real time.
3. Build trust through ratings, verification, and repeat relationships.
4. Maintain marketplace liquidity in focused launch zones.

## Non-Goals For MVP

- Built-in payment processing
- Multi-city launch orchestration
- Web dashboard
- Enterprise admin tooling beyond basic moderation support
- Full route optimization

## User Types

### Customer

A user who creates a task and selects a worker.

### Worker

A user who enables availability, responds to tasks, and completes local jobs.

Users can act in both roles.

## MVP Features

### 1. Authentication And Profiles

- Phone number authentication
- Basic profile setup
- Verification state
- Worker or customer usage without separate accounts

Acceptance criteria:

- A new user can sign in with a phone number.
- A signed-in user can create or edit a profile.
- A user profile stores public trust signals.

### 2. Task Posting

- Title, description, category, budget, location, optional images
- Expiration timestamp
- Task status lifecycle

Acceptance criteria:

- A customer can create a task in less than 2 minutes.
- A posted task becomes visible to eligible nearby workers.
- Expired tasks are hidden from active discovery.

### 3. Opportunity Feed

- Sorted by proximity and freshness
- Live updates
- Task preview cards
- Worker availability-aware visibility
- Optional map-based browsing

Acceptance criteria:

- An available worker sees newly posted nearby tasks without manual refresh.
- A worker can open a task from the feed and respond.
- A worker marked busy or offline does not see other users' open tasks as actionable opportunities.

### 4. Task Responses

- Accept budget
- Offer revised budget
- Add short message
- Show ETA where possible

Acceptance criteria:

- A worker can send a response to an open task.
- A customer can compare multiple responses and choose one.

### 5. Chat And Confirmation

- Real-time chat thread per task
- Price confirmation
- Location sharing
- Task acceptance confirmation
- Offer messages inside the task thread

Acceptance criteria:

- Both parties can exchange messages in real time.
- The selected worker and customer can confirm the final job terms.
- Either participant can send an offer message with a revised price inside the chat thread.

### 6. Ratings And Reputation

- Mutual rating after completion
- Aggregated trust metrics on profile

Acceptance criteria:

- Both users can rate each other once per completed task.
- Profile summary updates after a rating is submitted.

### 7. Notifications

- New nearby task alerts for workers
- New response alerts for customers
- Chat message alerts
- Device token registration for real push delivery
- In-app activity inbox with unread state

Acceptance criteria:

- Available workers receive notifications for matching nearby tasks.
- Customers are alerted when responses arrive.
- Signed-in devices register push tokens against the user profile when permissions are granted.

### 8. Live Location During Active Tasks

- Worker can share live location for matched or in-progress tasks
- Customer can view current worker location during the active task window
- Shared location stops when the worker stops tracking or the task ends

Acceptance criteria:

- A matched worker can start live location sharing from task detail.
- The customer can see the latest shared worker location for the active task.
- Live location is not writable by non-assigned users.

## Key Status Models

### Worker Availability

- offline
- available
- busy

### Task Lifecycle

- open
- matched
- in_progress
- completed
- cancelled
- expired

## Marketplace Rules

- Only available workers should receive live task alerts.
- Notification radius expands gradually when a task lacks responses.
- Customers should receive budget increase suggestions when response count is low.
- Trusted workers can receive first-priority task exposure in later phases.
- Customers can save proven workers and reuse that network for faster repeat hiring.

## Success Metrics

- Time to first worker response
- Task fill rate
- Task completion rate
- Average worker response time
- Weekly active workers
- Weekly active customers
- Repeat customer rate
- Rating distribution

## Risks

- Low worker density causing empty feeds
- Delayed notifications reducing real-time value
- Fake or low-quality accounts damaging trust
- Price negotiation friction causing drop-off

## MVP Release Principle

Optimize for one launch area with strong activity density before expanding to more zones.