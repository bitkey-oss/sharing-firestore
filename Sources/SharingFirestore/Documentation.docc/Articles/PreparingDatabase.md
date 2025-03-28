# Preparing Firestore

set up and configure Firestore for use with SharingFirestore.

## Overview

Before you can use SharingFirestore effectively, you need to properly set up and configure Firebase's Firestore. This article covers the essential steps to prepare Firestore for your application, including:

* [Step 1: Adding Firebase to your project](#Step-1-Adding-Firebase-to-your-project)
* [Step 2: Initializing Firebase](#Step-2-Initializing-Firebase)
* [Step 3: Configuring Firestore](#Step-3-Configuring-Firestore)
* [Step 4: Preparing security rules](#Step-4-Preparing-security-rules)
* [Step 5: Setting Firestore instance in SharingFirestore](#Step-5-Setting-Firestore-instance-in-SharingFirestore)

### Step 1: Adding Firebase to your project

To use Firestore, you first need to add Firebase to your project. If you haven't done this already, follow these steps:

1. Create a Firebase project at [firebase.google.com](https://firebase.google.com)
2. Register your iOS app in the Firebase console
3. Download the `GoogleService-Info.plist` file
4. Add this file to your Xcode project

Then add the Firebase dependencies to your project. With Swift Package Manager:

```swift
// In Package.swift
dependencies: [
  .package(url: "https://github.com/firebase/firebase-ios-sdk.git", from: "10.0.0"),
  .package(url: "https://github.com/bitkey-oss/sharing-firestore.git", from: "0.1.0")
]

// Target dependencies
.target(
  name: "YourApp",
  dependencies: [
    .product(name: "FirebaseFirestore", package: "firebase-ios-sdk"),
    .product(name: "SharingFirestore", package: "sharing-firestore"),
  ]
)
```

Or with CocoaPods:

```ruby
# In Podfile
pod 'Firebase/Firestore'
pod 'SharingFirestore', '~> 0.1.0'
```

### Step 2: Initializing Firebase

Firebase should be initialized early in your app's lifecycle. For SwiftUI apps:

```swift
import Firebase
import SharingFirestore
import SwiftUI

@main
struct MyApp: App {
  init() {
    FirebaseApp.configure()
    // Further configuration in Step 5
  }

  var body: some Scene {
    WindowGroup {
      ContentView()
    }
  }
}
```

For UIKit apps with AppDelegate:

```swift
import Firebase
import SharingFirestore
import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    FirebaseApp.configure()
    // Further configuration in Step 5
    return true
  }
}
```

### Step 3: Configuring Firestore

For most applications, the default Firestore configuration works well. However, you might want to customize settings based on your app's needs:

```swift
let settings = Firestore.firestore().settings
// Set cache size (100MB)
let gcsettings = MemoryLRUGCSettings(sizeBytes: 100 * 1024 * 1024 as NSNumber)
settings.cacheSettings = MemoryCacheSettings(garbageCollectorSettings: gcsettings)

// Enable offline persistence
settings.isPersistenceEnabled = true

// Set host for Firebase emulator (for local development)
#if DEBUG
settings.host = "localhost:8080"
settings.isSSLEnabled = false
#endif

// Apply settings
let firestore = Firestore.firestore()
firestore.settings = settings
```

#### Configuring for development and testing

During development, you might want to use the Firebase Emulator Suite:

1. Install the Firebase CLI tools
2. Start the Firestore emulator:
   ```bash
   firebase emulators:start --only firestore
   ```
3. Configure your app to use the emulator:
   ```swift
   #if DEBUG
   let settings = Firestore.firestore().settings
   settings.host = "localhost:8080"
   settings.isSSLEnabled = false
   Firestore.firestore().settings = settings
   #endif
   ```

### Step 4: Preparing security rules

For production applications, you need to define security rules for your Firestore database. While this is outside the scope of SharingFirestore itself, having proper rules is essential for a secure application.

Basic security rules template:

```javascript
// In firestore.rules
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Authentication-based rules
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;

      // Subcollection rules
      match /todos/{documentId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
    }

    // Public data rules
    match /public/{document=**} {
      allow read: if true;
      allow write: if request.auth != null;
    }
  }
}
```

Deploy these rules using the Firebase CLI:

```bash
firebase deploy --only firestore:rules
```

### Step 5: Setting Firestore instance in SharingFirestore

Once Firebase is configured, set the default Firestore instance for SharingFirestore using the `prepareDependencies` function:

```swift
import Firebase
import SharingFirestore
import SwiftUI

@main
struct MyApp: App {
  init() {
    FirebaseApp.configure()

    let firestore = Firestore.firestore()
    // Optional: Configure firestore settings here

    prepareDependencies { dependencies in
      dependencies.defaultFirestore = firestore
    }
  }

  var body: some Scene {
    WindowGroup {
      ContentView()
    }
  }
}
```

> Important: You should only set the `defaultFirestore` once in your application's lifetime. Doing so multiple times will produce a runtime warning.

For testing and previews, you should also configure the dependency:

```swift
#Preview {
  let _ = prepareDependencies { dependencies in
    if !FirebaseApp.app() {
      FirebaseApp.configure()
    }
    dependencies.defaultFirestore = Firestore.firestore()
  }

  return ContentView()
}
```

For unit tests:

```swift
@Test(.dependency(\.defaultFirestore, mockFirestore))
func testFeature() {
  // Test using mock Firestore
}
```

You can create a helper function to set up Firestore consistently across your app:

```swift
func setupFirestore(forTesting: Bool = false) -> Firestore {
  if FirebaseApp.app() == nil {
    FirebaseApp.configure()
  }

  let firestore = Firestore.firestore()
  let settings = firestore.settings

  #if DEBUG
  if forTesting {
    // Use local emulator for testing
    settings.host = "localhost:8080"
    settings.isSSLEnabled = false
  }
  Firestore.enableLogging(true)
  #endif

  // Set other settings like cache size, persistence, etc.
  firestore.settings = settings

  return firestore
}
```

This approach ensures consistent configuration across your application, tests, and previews.
