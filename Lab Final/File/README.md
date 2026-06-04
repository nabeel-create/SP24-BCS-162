# AI Attendance System — Flutter App

A complete Flutter mobile app that mirrors the Expo app's design and features.
Uses Supabase for authentication, the shared Express API for all data, and the
Python ArcFace service for face-recognition attendance.

---

## Quick Start

### 1. Configure credentials

Open `lib/config/app_config.dart` and fill in your values — or pass them as
`--dart-define` flags at build time:

```
flutter build apk \
  --dart-define=API_BASE_URL=https://<your-replit-domain>/api \
  --dart-define=FACE_API_URL=https://<your-replit-domain>/face \
  --dart-define=SUPABASE_URL=https://<project>.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=<your-anon-key>
```

### 2. Install Flutter (≥ 3.19)

```bash
# Install Flutter SDK from https://flutter.dev/docs/get-started/install
flutter doctor   # verify setup
```

### 3. Run the app

```bash
cd nabeel
flutter pub get
flutter run                  # connected Android / iOS device
flutter run -d chrome        # Flutter Web (for quick testing)
```

### 4. Build for release

```bash
flutter build apk --release  # Android APK
flutter build ios --release  # iOS (requires macOS + Xcode)
```

---

## Project Structure

```
lib/
  main.dart                  # App entry, Supabase init, auth gate
  config/app_config.dart     # API URLs and Supabase credentials
  theme/                     # Colors (matching Expo) + Material theme
  models/models.dart         # Data models
  services/
    api_service.dart         # Express API HTTP client
    face_api_service.dart    # Python ArcFace API client
  navigation/main_nav.dart   # Bottom tab navigation (5 tabs)
  screens/
    auth/login_screen.dart   # Email + Google sign-in
    dashboard/               # Stats grid, trend chart, today's overview
    students/                # List, detail, add, face registration
    attendance/              # Records, bulk marking, camera recognition
    departments/             # CRUD with sections
    teachers/                # CRUD
    subjects/                # CRUD
    reports/                 # Defaulters list with threshold slider
    more/                    # Teachers, Subjects, Reports, Sign out
  widgets/
    stat_card.dart           # Dashboard stat cards
    status_badge.dart        # Present / Absent / Late chips
    mini_chart.dart          # Line + bar charts (fl_chart)
    loading_view.dart        # Shared loading/error/empty states
```

---

## Face Recognition (ArcFace)

The Python service at `artifacts/face-api/` runs a FastAPI server using
**DeepFace + ArcFace** — one of the best face recognition models available.

- **Register**: Camera → 5 angles captured → ArcFace 512-dim embedding →
  stored via Express API `/students/:id/face`
- **Recognize**: Camera frame → Python `/recognize` with enrolled embeddings →
  returns matched student IDs → mark all present

The Flutter app and Python service only use 512-dim ArcFace embeddings.
Students registered via the web app (128-dim face-api.js) need to re-register
through the Flutter app for camera attendance to work.

---

## Color Palette (matches Expo app exactly)

| Color         | Hex       |
|---------------|-----------|
| Primary       | `#3B82F6` |
| Background    | `#F1F5F9` |
| Card          | `#FFFFFF` |
| Present       | `#22C55E` |
| Absent        | `#EF4444` |
| Late          | `#F59E0B` |
| Border        | `#E2E8F0` |
| Muted text    | `#64748B` |
