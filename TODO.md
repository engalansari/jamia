# Jamia TODO

## Portable tools
- [x] Flutter SDK is inside Jamia/tools/flutter
- [x] Use Jamia/flutter.cmd or Jamia/flutter.ps1 to run Flutter

## Stage 1: Project setup
- [x] Choose approach: Flutter + Firebase
- [x] Start with Arabic and RTL
- [x] Install Flutter SDK or add it to PATH
- [x] Run flutter doctor
- [x] Create Flutter project
- [x] Set app name to Jamia
- [x] Configure RTL layout
- [x] Create base folder structure

## Stage 2: Data models
- [x] Users
- [x] Categories
- [x] Units
- [x] Items
- [x] Rounds
- [x] Requests
- [x] Logs
- [x] Notifications

## Stage 3: Firebase
- [x] Create or connect Firebase project
- [x] Connect Android app
- [ ] Connect iOS later when iOS environment is available
- [x] Configure Authentication client service
- [x] Configure Firestore client service and local rules
- [x] Configure Storage client service and local rules
- [x] Configure FCM client service
- [x] Configure basic security rules locally

## Stage 4: Auth and roles
- [x] Login screen
- [x] Username and password login
- [x] Admin role
- [x] Regular user role
- [x] Disable self registration

## Stage 5: Home and rounds
- [x] Current round
- [x] Time remaining
- [x] Request count
- [x] Add request button
- [x] Favorites button
- [x] I am at the co-op button
- [x] Open new round
- [x] Close requests automatically

## Stage 6: Admin management
- [x] Manage users
- [x] Manage categories
- [x] Manage units
- [x] Manage base items
- [x] Manage favorites

## Stage 7: Requests
- [x] Add request from saved items
- [x] Quantity
- [x] Unit
- [x] Priority colors
- [x] Optional image
- [x] Optional note
- [x] Edit before closing
- [x] Delete before closing
- [x] Block edits after closing

## Stage 8: Purchase flow
- [x] Current requests list
- [x] Purchased button
- [x] Move request to purchased list
- [x] Record purchaser and time
- [x] Keep unpurchased items in needed list

## Stage 9: Logs and search
- [x] Operation log
- [x] Search by item
- [x] Search by user
- [x] Search by category
- [x] Search current requests
- [x] Search purchased requests

## Stage 10: Notifications
- [x] New request notification
- [x] Edit request notification
- [x] Delete request notification
- [x] Purchased notification
- [x] New round notification
- [x] Close requests notification
- [x] Admin message notification

## Stage 11: Testing and delivery
- [x] Run app locally
- [x] Run flutter analyze
- [x] Run flutter test
- [x] Build debug APK
- [x] Build latest Android debug APK with English support
- [x] Install debug APK on Android phone
- [x] Install latest debug APK with English support on Android phone
- [x] Install latest release APK on Android phone for private family use
- [x] Fix release startup crash from missing Crashlytics Gradle plugin
- [x] Confirm Firebase Auth login works for admin account
- [x] Confirm Firestore rules issue was found and fixed in Firebase Console
- [x] Remove temporary UID/debug error display from app
- [ ] Test full admin flow
- [ ] Test regular user flow
- [ ] Test round open/close
- [x] Add default catalog button when request items are empty
- [x] Group request items by category before choosing an item
- [x] Replace manual item categoryId with category picker in admin
- [ ] Test add/purchase requests
- [ ] Test images
- [ ] Test basic notifications

## Stage 11 note
- [ ] Continue live Firebase phone tests if phone internet/DNS cannot reach firestore.googleapis.com

## Stage 12: English after approval
- [x] Add English translation files
- [x] Add language switch
- [x] Test English LTR layout

## Stage 13: Private Android delivery
- [x] Prepare app icons and splash screens
- [x] Configure Firebase production settings
- [x] Build Android release APK for direct family install
- [ ] Build iOS later only if the family needs iPhone support
- [x] Store listing skipped: private family app, direct APK install only
- [x] Google Play upload skipped by decision: private family app
- [x] Prepare private release notes and versioning

## Stage 14: Monitoring and maintenance
- [x] Add Crashlytics package and app error hooks
- [x] Add Analytics package and navigation observer
- [x] Verify monitoring build after adding Crashlytics and Analytics
- [x] Collect user feedback channels
- [x] Plan bug-fix and iteration cycle
- [x] Update documentation and README
- [x] Improve internal UI styling and typography
- [x] Apply blue mobile operations inspired theme

## Stage 15: Production security rules
- [x] Review Firestore and Storage production rule drafts
- [x] Add explicit production Firebase config for rule validation
- [x] Allow regular users to update only their own lastLogin field
- [x] Align operation log collection name with production rules
- [x] Align request image uploads with the production Storage path
- [x] Validate production Firestore and Storage rules with Firebase emulators
- [x] Test full admin flow against staging or emulator
- [x] Test regular user flow against staging or emulator
- [x] Tighten request ownership, purchase, delete, and image-upload rules
- [x] Deploy production Firestore rules
- [x] Deploy production Storage rules
- [x] Build and install updated Android APK after production rules deployment
- [x] Smoke-test updated Android app launch on phone after production rules deployment
- [ ] Get explicit approval before starting any further phone-version work
- [ ] Test production rules from Android phone after deployment

## Stage 16: Design and workflow adjustments
- [x] Improve faded/low-contrast fonts across the app
- [x] Change the general app background to white
- [x] Remove the home-screen user info square/card
- [x] Add a top-right circular user badge showing the username or first initial
- [x] Move the theme/design option into the hamburger menu
- [x] Add a hamburger-menu option for choosing background colors
- [x] Review and redesign the notification settings list
- [x] Make the notification enable button clearly show whether notifications are enabled
- [x] Move the notification enable/control UI to the right place after redesign
- [x] Add an option to close/cancel the selected "I am at the co-op" time
- [x] Send a notification when the user chooses the "I am at the co-op" time
- [x] Fix request-add notifications so only the first request in a new add session sends a notification
- [x] Stop sending a notification for every later item added in the same request-add session
- [x] Add a practical confirmation dialog before canceling/deleting an item from the purchase list by swipe
- [x] Make purchase-list swipe cancel work clearly to the right and left without accidental deletion
- [x] Investigate and improve the delay when adding an item
- [x] Do not start phone-version work for these design changes without explicit approval





















