# Firebase Emulator Setup

This directory contains the configuration for running Firebase Emulator locally during development. The Firebase Emulator Suite provides local emulation of Firebase services, allowing you to develop and test your SharingFirestore implementation without connecting to production Firebase resources.

## Starting Emulators

To start the Firebase Emulator locally:

```shell
$ firebase emulators:start --project demo-project
```

## Configuring Your App for the Emulator

When working with SharingFirestore in development mode, you can point your app to the local emulator:

```swift
#if DEBUG
func setupFirestore() -> Firestore {
  let settings = Firestore.firestore().settings
  settings.host = "localhost:8080"  // Firestore emulator default port
  settings.isSSLEnabled = false

  let firestore = Firestore.firestore()
  firestore.settings = settings
  Firestore.enableLogging(true)  // Helpful for debugging

  return firestore
}
#endif

// In your app initialization
prepareDependencies {
  FirebaseApp.configure()
  $0.defaultFirestore = setupFirestore()
}
```

## Sample Configuration

This directory includes:

- `firebase.json` - Firebase project configuration
- `firestore.rules` - Security rules for Firestore
- `firestore.indexes.json` - Firestore indexes configuration

For more information about Firebase Emulator Suite, see the [official documentation](https://firebase.google.com/docs/emulator-suite).
