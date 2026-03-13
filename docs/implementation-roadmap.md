# Implementation Roadmap

## Delivery Strategy

Build the product in thin vertical slices so the team can test the marketplace loop early instead of building isolated UI screens first.

## Phase 0: Foundation

Outcome:

- Working Flutter app shell
- Firebase project connected
- CI basics and environment setup documented

Tasks:

1. Create Flutter project structure.
2. Configure Firebase for Android and iOS.
3. Add core dependencies for auth, Firestore, messaging, storage, maps, and state management.
4. Define shared app theme, routing, and environment config.

## Phase 1: Identity And Profiles

Outcome:

- Users can authenticate and manage profiles.

Tasks:

1. Implement phone authentication.
2. Build onboarding and profile completion.
3. Persist user documents in Firestore.
4. Add availability toggle for workers.

Definition of done:

- A new user can sign in and create a usable profile.
- A returning user stays authenticated.

## Phase 2: Task Marketplace Core

Outcome:

- Customers can post tasks and workers can discover and respond.

Tasks:

1. Build post task form.
2. Implement task persistence with lifecycle fields.
3. Build live opportunity feed.
4. Build task detail screen.
5. Implement worker response creation.
6. Build customer response review flow.

Definition of done:

- A task can be posted, discovered, responded to, and matched.

## Phase 3: Chat And Completion

Outcome:

- Selected worker and customer can negotiate and complete the task.

Tasks:

1. Build realtime task chat.
2. Support price negotiation messages.
3. Add task confirmation and in-progress states.
4. Add completion flow.
5. Add two-way ratings.

Definition of done:

- The full customer-worker transaction loop works inside the app.

## Phase 4: Notifications And Maps

Outcome:

- Opportunity discovery becomes genuinely real time.

Tasks:

1. Add FCM token registration.
2. Send worker task alerts through Cloud Functions.
3. Add customer response alerts.
4. Add message alerts.
5. Build map view with nearby tasks.

Definition of done:

- Workers receive nearby alerts quickly enough for the platform to feel live.

## Phase 5: Marketplace Optimization

Outcome:

- The launch area has better liquidity and conversion.

Tasks:

1. Add wave-based notification radius expansion.
2. Add activity indicators for customers.
3. Add budget suggestion prompts.
4. Add trusted worker shortcuts.
5. Build worker dashboard metrics.

## Recommended Initial Milestones

### Milestone 1

Auth, profiles, and availability status.

### Milestone 2

Task creation, feed, detail, and response flow.

### Milestone 3

Chat, completion, and ratings.

### Milestone 4

Push notifications and map view.

## Team Roles

Suggested split for a small team:

- Product and UX: task flow, trust UX, launch metrics
- Mobile engineering: Flutter features and state management
- Backend engineering: Firebase rules, functions, notifications, geolocation logic
- Growth and operations: worker onboarding and local launch execution

## Launch Checklist

Before public launch in a zone:

1. Recruit at least 20 active workers.
2. Seed initial customer demand.
3. Verify notification latency in the target area.
4. Validate safety and abuse reporting flows.
5. Measure time to first response and task completion rate.

## Recommended Next Build Step

The next practical step is to scaffold the Flutter application and lock the Firebase contract around the collections defined in [data-model.md](data-model.md).