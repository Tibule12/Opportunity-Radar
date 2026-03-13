# Opportunity Radar

Opportunity Radar is a real-time local opportunity marketplace that connects people who need physical tasks completed with nearby workers who can respond within minutes.

The product is designed for fast-moving, location-based jobs such as deliveries, transport, errands, moving help, and urgent local assistance. It combines a live opportunity feed, instant worker responses, negotiation chat, and a reputation system to create a structured alternative to informal messaging-based coordination.

## Mission

Connect people with nearby opportunities and trusted local help in real time.

## Problem

Local customers often need quick help, but finding reliable workers nearby is slow and unstructured. Workers also struggle to discover earning opportunities fast enough, especially for short, physical tasks.

Existing chat tools solve communication, but they do not solve discovery, matching, trust, task visibility, or reputation.

## Solution

Opportunity Radar provides a live local marketplace where customers can post tasks and nearby workers can respond immediately.

Core platform capabilities:

- Real-time task posting
- Nearby opportunity feed
- Map-based discovery
- Instant worker alerts
- Response comparison and selection
- In-app chat and price negotiation
- Ratings, trust, and verification
- Worker availability mode

## Target Users

### Workers

- Taxi drivers
- Delivery drivers
- Students
- Freelancers
- Gig workers
- Informal workers

### Customers

- Individuals needing errands completed
- Small businesses
- Offices
- Local shops
- Restaurants

## Core User Flows

### Worker Flow

1. Open app
2. Enable availability mode
3. View nearby opportunities
4. Open a task
5. Accept, negotiate, or message
6. Get selected by customer
7. Chat and confirm details
8. Complete task
9. Receive rating and payment

### Customer Flow

1. Open app
2. Tap post task
3. Enter task details
4. Nearby workers receive alerts
5. Review incoming responses
6. Select a worker
7. Chat and confirm details
8. Mark task complete
9. Leave rating

## Core Features

### User Accounts

- Phone authentication with Firebase Authentication
- Name, phone number, profile photo, rating, completed task count, verification status
- Dual role support so a user can act as customer and worker

### Opportunity Feed

- Main screen for nearby live tasks
- Distance-aware task cards
- Time since posting
- Budget visibility
- Fast response actions

Example feed item:

- Deliver parcel
- R80
- 500m away
- Posted 30 seconds ago

### Opportunity Map

- User location
- Nearby opportunities
- Worker locations when relevant
- Google Maps integration

### Task Posting

Customers can create tasks with:

- Title
- Description
- Category
- Budget
- Location
- Optional photos
- Expiration timer

Categories:

- Delivery
- Transport
- Errands
- Moving Help
- Other

### Instant Response System

Workers can:

- Accept task
- Offer new price
- Message customer

Customers see ranked response options such as:

- Sipho, arriving in 5 minutes, R120
- Thabo, arriving in 7 minutes, R110
- Lerato, arriving in 6 minutes, R120

### Chat and Negotiation

- Real-time messaging with Firestore
- Text chat
- Location sharing
- Quick price offers
- Task confirmation

### Reputation System

Ratings include:

- Reliability
- Communication
- Speed
- Professionalism

Profile trust signals include:

- Rating score
- Completed tasks
- Response speed
- Trust badges

### Worker Availability Mode

Workers can switch between:

- Available
- Busy
- Offline

When a worker is available, the system pushes nearby task alerts immediately.

### Trusted Worker Circles

- Customers can save preferred workers
- Tasks can be offered to trusted workers first
- Improves repeat usage and trust

### Worker Network Invites

- Referral-based invites
- Worker growth loops
- Future referral rewards

### Worker Dashboard

- Today's earnings
- Tasks completed
- Average rating
- Leaderboard ranking

### Safety Features

- User verification
- Reporting system
- Blocking
- Emergency support
- Profile verification states

## Marketplace Stability Strategy

This product only works if the supply side is active. The initial system should explicitly address marketplace liquidity.

### Dynamic Task Distribution

Notify workers gradually by radius:

1. 500m
2. 1km
3. 3km

### Activity Indicators

Customers should see confidence-building status updates such as:

- Searching for workers
- 3 workers notified
- 1 worker viewing task

### Priority Worker Matching

Rank worker visibility using:

- Distance
- Availability
- Rating
- Response speed

### Budget Suggestions

If a task receives no responses, prompt the customer to increase the offer.

### Launch Requirement

Start each launch zone with at least 20 active workers.

## Technology Stack

### Mobile

- Flutter

### Backend

- Firebase Authentication
- Cloud Firestore
- Firebase Cloud Messaging
- Firebase Storage
- Firebase Cloud Functions

### Maps

- Google Maps API

## Proposed Data Model

Primary collections:

- users
- tasks
- task_responses
- messages
- ratings
- worker_networks
- notifications

See [docs/data-model.md](docs/data-model.md) for the detailed schema.

## Product Screens

- Splash screen
- Onboarding
- Login and phone verification
- Opportunity feed
- Map view
- Post task screen
- Task detail screen
- Worker response screen
- Chat screen
- Worker dashboard
- Profile screen

## MVP Scope

### Phase 1

- Flutter project setup
- Firebase integration
- Authentication
- User profiles

### Phase 2

- Task creation
- Opportunity feed
- Task detail screen
- Worker responses

### Phase 3

- Chat system
- Task confirmation
- Ratings

### Phase 4

- Push notifications
- Map view
- Worker dashboard
- UI improvements

See [docs/implementation-roadmap.md](docs/implementation-roadmap.md) for the execution plan.

## Launch Strategy

Launch in one small area first, for example Sandton.

Initial go-to-market approach:

- Recruit the first 20 workers manually
- Seed early tasks manually
- Partner with local shops, restaurants, and offices

## Long-Term Vision

Build the largest real-time opportunity network where people open the app to find work, get help, and discover local opportunities instantly.

## Repository Docs

- [docs/product-requirements.md](docs/product-requirements.md)
- [docs/technical-architecture.md](docs/technical-architecture.md)
- [docs/data-model.md](docs/data-model.md)
- [docs/implementation-roadmap.md](docs/implementation-roadmap.md)

## Current Repository Setup

This repository now includes a manual starter scaffold for the Flutter client and Firebase backend artifacts.

Included:

- Flutter package manifest in `pubspec.yaml`
- App entrypoint and initial screen shell under `lib/`
- Firebase config files for Firestore, Storage, and Functions
- TypeScript Cloud Functions scaffold under `functions/`

Current implemented product slices:

- Phone authentication and profile completion
- Firestore-backed task posting and live feed
- Task detail, worker responses, and worker selection
- Task chat with text, offer, and system messages
- Matched and completed task state changes
- Mutual ratings with aggregate profile updates
- Distance-aware feed ordering and availability gating
- Map browsing with category and radius filters
- Device location autofill, reverse geocoding, and live worker location sharing for active tasks
- In-app notifications inbox, unread badge, and live dashboard activity
- FCM token registration hooks and push fan-out from Cloud Functions
- Trusted worker save/reuse loop with prioritized task fan-out

## Local Setup

### Prerequisites

- Flutter SDK installed and available on `PATH`
- Firebase CLI installed
- A configured Firebase project
- Android Studio or Xcode depending on target platform

### Flutter App Bootstrap

The environment used to prepare this repo did not have Flutter installed, so the platform folders were not generated automatically.

After installing Flutter, run the following from the repository root:

```powershell
flutter create .
flutter pub get
```

Then install the newly added location and geocoding dependencies if your lockfile is still stale:

```powershell
flutter pub get
```

Then regenerate Firebase platform options with FlutterFire CLI if you are using it:

```powershell
dart pub global activate flutterfire_cli
flutterfire configure
```

### Firebase Backend Bootstrap

Install backend dependencies:

```powershell
cd functions
npm install
```

Deploy rules or test locally with the Firebase CLI once your project is configured.

## Mobile Platform Setup

The app now depends on Google Maps, geolocator, and geocoding. That means local platform configuration is required before mobile builds will succeed.

See [docs/mobile-platform-setup.md](docs/mobile-platform-setup.md) for:

- Android permissions and Maps API key setup
- iOS permissions and location usage strings
- Notes for geolocator and geocoding
- Live worker tracking implications for testing

## Immediate Next Build Target

The next implementation target should be local Flutter bootstrap and platform permission wiring so the map, device location, live worker tracking, and FCM flows can be tested on-device.