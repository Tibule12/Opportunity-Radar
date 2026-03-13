# Firebase Local Setup

These steps are required if you want Opportunity Radar to run the real marketplace instead of the fallback setup screen.

## 1. Install Firebase CLI

```bash
npm install -g firebase-tools
firebase login
```

## 2. Install FlutterFire CLI

```bash
dart pub global activate flutterfire_cli
```

Make sure Dart global executables are on your path. If needed:

```bash
export PATH="$PATH:$HOME/.pub-cache/bin"
```

## 3. Create Or Select A Firebase Project

From the Firebase Console, create a project for Opportunity Radar or choose an existing one.

Enable at least:

- Authentication
- Cloud Firestore
- Cloud Functions
- Cloud Messaging
- Storage

## 4. Register App Platforms

Register the platforms you want to run locally:

- Android
- Web
- Linux desktop only if you plan to use desktop Firebase support through FlutterFire options

## 5. Generate FlutterFire Config

From the repository root:

```bash
flutterfire configure
```

This should generate and replace:

- `lib/firebase_options.dart`

For Android, it should also wire in the Android Firebase app configuration.

## 6. Verify The App Now Boots Into Firebase

Run:

```bash
flutter pub get
flutter run -d chrome
```

or:

```bash
flutter run -d linux
```

If Firebase is configured correctly, the app should move past the setup-required screen.

## 7. Backend Project Setup

Inside the functions folder:

```bash
cd functions
npm install
npm test
cd ..
```

If you want to use emulators locally:

```bash
firebase emulators:start
```

## 8. Minimum Firebase Product Configuration

### Authentication

- Enable Phone authentication

### Firestore

- Create the Firestore database
- Deploy rules and indexes:

```bash
firebase deploy --only firestore:rules,firestore:indexes
```

### Storage

- Create the default storage bucket
- Deploy storage rules:

```bash
firebase deploy --only storage
```

### Functions

- Deploy functions when ready:

```bash
firebase deploy --only functions
```

## 9. Maps And Platform Keys

This app also needs Google Maps keys for the map experience.

Use `docs/mobile-platform-setup.md` for the Android and iOS map key steps.

## 10. Real Local Smoke Test

Once Firebase is configured, this is the quickest useful smoke test:

1. Launch the app
2. Complete profile setup
3. Create one customer account and one worker account
4. Put the worker online
5. Post a task
6. Confirm the worker sees the opportunity
7. Respond, match, chat, and complete the task
8. Confirm the earnings ledger updates