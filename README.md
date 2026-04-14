# Stop Alert App

Stop Alert is an offline-first Flutter travel alarm app that alerts you before you reach your destination (bus, train, or other transit). It is designed to keep tracking in the background and notify you with progressive alerts as you get closer.

## Features

- Offline distance tracking to destination
- Progressive alert levels as you approach the stop
- Background tracking support on Android
- Local trip/history storage
- Destination and trip management UI

## Tech Stack

- Flutter (Dart)
- OpenStreetMap via `flutter_map`
- GPS/location via `geolocator`
- Local notifications via `flutter_local_notifications`
- Background service via `flutter_background_service`
- Local persistence via `hive`

## Project Structure

- `lib/engines/` core tracking and alert logic
- `lib/providers/` app state providers
- `lib/screens/` UI screens
- `lib/services/` storage/audio services
- `lib/widgets/` reusable UI components
- `assets/` branding and alarm sounds
- `website/` lightweight web companion/static site

## Getting Started

### Prerequisites

- Flutter SDK 3.4+
- Android Studio (or VS Code + Android toolchain)
- Android device/emulator for testing background behavior

### Install Dependencies

```bash
flutter pub get
```

### Run The App

```bash
flutter run
```

### Build APK

```bash
flutter build apk --release
```

## Android Notes

For accurate alerts and background operation, grant:

- Location permissions (including background location)
- Notification permission
- Battery optimization exemptions (if needed on specific OEM devices)

## Repository

GitHub: https://github.com/JewelArimattom/Stop-Alert-App-
