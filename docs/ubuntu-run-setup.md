# Ubuntu Run Setup

These steps let you clone Opportunity Radar on Ubuntu and run it in Chrome or Linux desktop mode.

## 1. Install Flutter On Ubuntu

One simple path is Snap:

```bash
sudo snap install flutter --classic
flutter --version
```

If Snap is not available in your environment, use the official Flutter Linux tarball instead.

## 2. Install Linux Desktop Build Dependencies

```bash
sudo apt update
sudo apt install -y clang cmake ninja-build pkg-config libgtk-3-dev liblzma-dev curl git unzip xz-utils zip
```

## 3. Clone The Repository

```bash
git clone https://github.com/Tibule12/Opportunity-Radar.git
cd Opportunity-Radar
```

## 4. Enable Flutter Desktop Support

```bash
flutter config --enable-linux-desktop
flutter doctor -v
```

You should see at least:

- Linux desktop support
- Chrome or another Chromium-based browser if installed

## 5. Install Project Dependencies

```bash
flutter pub get
```

## 6. Run A Fast Preview In Chrome

```bash
flutter run -d chrome
```

This is the fastest way to see the UI.

## 7. Run The Linux Desktop App

```bash
flutter run -d linux
```

## 8. What You Will See Without Firebase Setup

If Firebase has not been configured on that machine yet, the app will open a setup-required screen instead of the live marketplace.

To run the real app experience, complete the Firebase steps in `docs/firebase-local-setup.md`.

## 9. Recommended Ubuntu Workflow

For the first preview:

1. Run `flutter pub get`
2. Run `flutter run -d chrome`
3. Confirm the app shell loads
4. Configure Firebase only after the UI boot path is confirmed