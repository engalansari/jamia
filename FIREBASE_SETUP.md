# Firebase Setup Notes

## Current Firebase project
- Project ID: `jamiaq8`
- Android package: `com.jamia`
- Android config file is installed at: `app/android/app/google-services.json`

## Completed in code
- Firebase packages added to Flutter.
- Firebase initializes before the app starts.
- Android Gradle uses Google Services plugin.
- Client services added for Authentication, Firestore, Storage, and FCM.
- Local Firestore and Storage rules are in `firebase/` and referenced by `firebase.json`.

## Still required in Firebase Console
- Enable Email/Password sign-in under Authentication.
- Create Firestore Database in production mode.
- Enable Firebase Storage.
- Add an iOS app with bundle ID `com.jamia`.
- Download `GoogleService-Info.plist` and place it at `app/ios/Runner/GoogleService-Info.plist`.

## Optional later
- Install Firebase CLI if you want to deploy rules from this folder.
- Deploy local rules after Firebase CLI login:
  - `firebase deploy --only firestore:rules`
  - `firebase deploy --only storage`
