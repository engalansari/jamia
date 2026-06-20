# Auth Setup Notes

Stage 4 uses Firebase Authentication with hidden internal email addresses.

## Username login mapping
When a user types a username, the app signs in with:

`username@jamia.local`

Example:

- username: `khaled`
- Firebase Auth email: `khaled@jamia.local`

## Required Firestore user document
Each Firebase Auth user must also have a document in `users/{uid}`.

Example fields:

```json
{
  "userId": "FIREBASE_AUTH_UID",
  "displayName": "خالد",
  "username": "khaled",
  "role": "admin",
  "status": "active",
  "createdAt": "2026-06-18T00:00:00.000Z",
  "lastLogin": null
}
```

Roles:

- `admin`
- `regular`

Statuses:

- `active`
- `disabled`

There is no self-registration screen. User creation will be added in Stage 6 admin management.
