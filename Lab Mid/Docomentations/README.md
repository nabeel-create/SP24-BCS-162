# Task Manager (Mid‑Term)

This is a Flutter + SQLite task management app built for the Mid‑Term Task (Spring 2026).  
It supports task creation, editing, deletion, categorization, repeats, progress tracking, exports, and notifications.

**Features**
1. Task management: add, edit, delete, complete, pin.
2. Categories + filters: Today, Completed, Repeated, Overdue.
3. Subtasks + progress tracking.
4. Repeat scheduling: daily or weekly with selected days.
5. Export: CSV, PDF, Email share.
6. Notifications: local reminders + Firebase Cloud Messaging (FCM).
7. Theme: light/dark toggle.

**Tech Stack**
1. Flutter
2. SQLite (sqflite)
3. Provider
4. Firebase Cloud Messaging

**Setup**
1. Install Flutter and Android SDK.
2. Run:
```powershell
flutter pub get
```
3. Run app:
```powershell
flutter run
```

**Build APK**
```powershell
flutter build apk --release
```

**Firebase Notes**
1. `android/app/google-services.json` is required.
2. FCM token prints to console on app start (debug).
3. Send test push from Firebase Console → Messaging.

**Known Device Limitation (OEM)**
Some devices (Vivo/Redmi) may block background local alarms even when permissions are enabled.  
FCM push works in background reliably. Local reminders still work while the app is running.

**Project Files**
1. `TESTING.md` – testing checklist/results
2. `DEMO_SCRIPT.md` – demo video script
