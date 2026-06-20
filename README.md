# Jamia

Jamia is a Flutter + Firebase household grocery coordination app.

## Current platform
- Android is configured and has debug/release APK builds for direct phone install.
- iOS project files exist, but final iOS configuration and archive require macOS and Xcode.

## Firebase
- Project ID: `jamiaq8`
- Android package: `com.jamia`
- Auth uses username mapping: `username@jamia.local`
- Firestore user documents live at `users/{uid}`

## Build commands
From `C:\Users\re273\Jamia\app`:

```powershell
..\flutter.cmd pub get
..\flutter.cmd analyze
..\flutter.cmd test
..\flutter.cmd build apk --debug
..\flutter.cmd build apk --release
```

## Private delivery
This app is for family use only. Current delivery is direct Android APK install, not Google Play or App Store upload.

## Release output
Android release APK:

```text
C:\Users\re273\Jamia\app\build\app\outputs\flutter-apk\app-release.apk
```

## Notes
- Keep test rules separate from production rules.
- Production rule drafts are in `firebase/firestore.production.rules` and `firebase/storage.production.rules`.
- Live phone tests need the phone to reach `firestore.googleapis.com`.

