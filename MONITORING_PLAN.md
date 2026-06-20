# Monitoring And Maintenance Plan

## Crash reporting
- Add Firebase Crashlytics before production store rollout.
- Verify crashes appear in Firebase Console from an internal test build.

## Analytics
- Add Firebase Analytics events for sign-in, open round, add request, purchase request, and close round.
- Avoid logging personal notes or image contents.

## Feedback
- Collect early feedback from household users after each test round.
- Track bugs in TODO.md or an issue tracker.

## Maintenance cycle
- Review feedback weekly during the first month.
- Ship small bug-fix builds before adding large features.
