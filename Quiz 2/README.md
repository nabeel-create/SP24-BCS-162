# ProfileVault — Flutter App (Nabeel)

A pure Flutter implementation of the ProfileVault user profile manager app.

## Features

- Add, edit, delete user profiles
- Photo picker (gallery + camera)
- Search by name, email, or age
- Sort by name, age, or date added (asc/desc)
- Delete confirmation dialog
- Skeleton shimmer loading
- Snackbar notifications (success, error, warning, info)
- Export/share JSON backup
- Full dark mode support
- Persistent storage with SharedPreferences
- Auto-generated avatar initials via UI Avatars API

## Project Structure

```
nabeel/
├── lib/
│   ├── main.dart                    # App entry point, theme setup
│   ├── constants/
│   │   └── app_colors.dart          # Color palette (light + dark)
│   ├── models/
│   │   └── user.dart                # User model with JSON serialization
│   ├── providers/
│   │   └── user_provider.dart       # State management (ChangeNotifier)
│   ├── screens/
│   │   ├── home_screen.dart         # Main user list screen
│   │   └── user_form_screen.dart    # Add/Edit user form
│   └── widgets/
│       ├── user_card.dart           # User list card widget
│       ├── skeleton_card.dart       # Shimmer loading card
│       └── custom_snackbar.dart     # Snackbar notification helper
├── pubspec.yaml                     # Flutter dependencies
└── README.md                        # This file
```

## How to Run

### Prerequisites
- Flutter SDK >= 3.2.0 installed ([flutter.dev](https://flutter.dev/docs/get-started/install))
- Dart SDK >= 3.2.0
- Android Studio or VS Code with Flutter extension
- Android emulator / iOS simulator OR a physical device

### Steps

1. Navigate to the nabeel folder:
   ```bash
   cd nabeel
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Run on device/emulator:
   ```bash
   flutter run
   ```

4. Build release APK (Android):
   ```bash
   flutter build apk --release
   ```

5. Build release IPA (iOS):
   ```bash
   flutter build ios --release
   ```

## Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| provider | ^6.1.2 | State management |
| shared_preferences | ^2.3.2 | Local data persistence |
| image_picker | ^1.1.2 | Photo gallery & camera |
| cached_network_image | ^3.4.1 | Cached avatar images |
| google_fonts | ^6.2.1 | Inter font family |
| share_plus | ^10.0.2 | Export/share backup |
| intl | ^0.19.0 | Internationalization |
| path_provider | ^2.1.4 | File system paths |

## Colors (matching original app)

| Name | Hex | Usage |
|------|-----|-------|
| Primary | #4A90D9 | Buttons, accents, highlights |
| Accent | #F5A623 | Camera button, young age badge |
| Background (light) | #F0F4F8 | Screen background |
| Card (light) | #FFFFFF | Card surfaces |
| Background (dark) | #0D1B2A | Dark screen background |
| Card (dark) | #1A2C3D | Dark card surfaces |
