# Focus Todo App — Install Guide

## What the app does
- Two tabs: 📚 Study | ✅ General
- Add, edit, delete tasks
- Progress bar per category
- Swipe left to delete
- Tap a task to edit
- Data saves locally on your phone

---

## Install in 5 steps

### Step 1 — Install Flutter
Download from https://flutter.dev/docs/get-started/install
Then run: `flutter doctor` (fix any issues shown)

### Step 2 — Enable USB Debugging on your phone
Settings → About Phone → tap Build Number 7 times
Then: Settings → Developer Options → USB Debugging ON

### Step 3 — Connect phone to PC via USB

### Step 4 — Open terminal in the todo_app folder and run:
```
flutter pub get
flutter run --release
```

### Step 5 — Or build an APK to install manually:
```
flutter build apk --release
```
APK will be at: `build/app/outputs/flutter-apk/app-release.apk`
Copy it to your phone and install it.

---

## Troubleshooting
- `flutter pub get` fails → check internet connection
- Device not found → try a different USB cable, check USB Debugging is on
- `flutter clean` then `flutter pub get` fixes most errors
