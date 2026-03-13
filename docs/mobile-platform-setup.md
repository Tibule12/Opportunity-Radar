# Mobile Platform Setup

This project now includes:

- `google_maps_flutter`
- `geolocator`
- `geocoding`

The current workspace does not contain generated platform folders, so these steps must be completed locally after running `flutter create .`.

## 1. Generate Platform Folders

From the repository root:

```powershell
flutter create .
flutter pub get
```

## 2. Android Setup

Update `android/app/src/main/AndroidManifest.xml` with at least:

```xml
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
```

If you intend to keep live worker tracking active in the background later, you will likely also need:

```xml
<uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION" />
```

Add your Google Maps API key inside the application block metadata:

```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="YOUR_ANDROID_MAPS_API_KEY" />
```

## 3. iOS Setup

Update `ios/Runner/Info.plist` with location usage descriptions:

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>Opportunity Radar uses your location to show nearby work and task locations.</string>
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>Opportunity Radar can share a worker's live location during an active matched task.</string>
```

If the app later supports background worker tracking, add the matching background mode capabilities in Xcode.

For Google Maps on iOS, configure the Maps SDK according to the `google_maps_flutter` setup guide and provide the iOS API key in `AppDelegate` or the recommended platform entrypoint for your Flutter version.

## 4. Google Maps Keys

Use separate restricted keys for:

- Android Maps SDK
- iOS Maps SDK

Lock each key to the correct package name or bundle identifier and relevant APIs.

## 5. Firebase And Device Testing

Before testing the location flows:

1. Run `flutterfire configure`
2. Add the generated Firebase config files to Android and iOS
3. Sign in with two accounts or two devices
4. Create a task with coordinates
5. Match a worker
6. Start live tracking from the worker side
7. Verify the customer sees the worker marker update on the task detail screen

## 6. Known Constraints In This Repo State

- Device location currently uses foreground permission only.
- Reverse geocoding is best-effort and depends on platform geocoding services.
- Live worker location updates are stored in the `worker_locations` collection only for matched or in-progress tasks.
- The current environment used to prepare this repo could not run Flutter, so platform behavior still needs to be verified locally.

## 7. Recommended Next Hardening

- Add background tracking only if the product explicitly needs it.
- Rate-limit live location update writes if battery or Firestore usage becomes an issue.
- Consider marker clustering once task density increases.
