# Testing Checklist (Mid‑Term)

**Environment**
1. Device: Android (vivo 1807)
2. Build: Debug and Release APK

**Core**
1. Add task with title/description/category/priority: Pass
2. Edit task details: Pass
3. Delete task: Pass
4. Mark complete: Pass (sound + haptic)
5. Pin/unpin task: Pass

**Filters**
1. Today filter: Pass
2. Completed filter: Pass
3. Repeated filter: Pass
4. Overdue filter: Pass

**Subtasks**
1. Add subtask: Pass
2. Toggle subtask completion: Pass
3. Progress bar updates: Pass

**Repeat**
1. Daily repeat: Pass
2. Weekly repeat + day selection: Pass

**Export**
1. CSV export: Pass
2. PDF export: Pass
3. Email share export: Pass

**Notifications**
1. Local reminder while app open: Pass
2. Local reminder background: Device‑limited on some OEMs
3. FCM push (background): Pass after Firebase setup

**UI/UX**
1. Dark mode toggle: Pass
2. Overdue badge: Pass

**Known Device Limitation**
Some OEMs (Vivo/Redmi) block scheduled local alarms in background. FCM works reliably.
