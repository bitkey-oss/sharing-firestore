import Dependencies
@preconcurrency import FirebaseFirestore

extension DependencyValues {
  /// The default database used by `query` and `sync`.
  ///
  /// Configure this as early as possible in your app's lifetime, like the app entry point in
  /// SwiftUI, using `prepareDependencies`:
  ///
  /// ```swift
  /// import SharingFirestore
  /// import SwiftUI
  ///
  /// @main
  /// struct MyApp: App {
  ///   init() {
  ///     prepareDependencies {
  ///       // Create database connection and run migrations...
  ///       FirebaseApp.configure()
  ///       $0.defaultFirestore = Firestore.firestore()
  ///     }
  ///   }
  ///   // ...
  /// }
  /// ```
  ///
  /// > Note: You can only prepare the database a single time in the lifetime of your app.
  /// > Attempting to do so more than once will produce a runtime warning.
  ///
  /// Once configured, access the database anywhere using `@Dependency`:
  ///
  /// ```swift
  /// @Dependency(\.defaultFirestore) var firestore
  ///
  /// let newItem = Item(/* ... */)
  /// let ref = firestore.collection("items")
  /// try ref.addDocument(from: newItem)
  /// ```
  ///
  /// See <doc:PreparingDatabase> for more info.
  public var defaultFirestore: Firestore {
    get { self[DefaultFirestoreKey.self] }
    set { self[DefaultFirestoreKey.self] = newValue }
  }

  private enum DefaultFirestoreKey: DependencyKey {
    static var liveValue: Firestore { testValue }
    static var testValue: Firestore {
      var message: String {
        @Dependency(\.context) var context
        if context == .preview {
          return """
            A blank, unconfigured database is being used. To set the database that is used by \
            'SharingFirestore', use the 'prepareDependencies' tool as early as possible in the lifetime \
            of your app:

                #Preview {
                  let _ = prepareDependencies {
                    FirebaseApp.configure()
                    $0.defaultFirestore = Firestore.firestore()
                  }

                  // ...
                }
            """
        } else {
          return """
            A blank, unconfigured database is being used. To set the database that is used by \
            'SharingFirestore', use the 'prepareDependencies' tool as early as possible in the lifetime \
            of your app:

                @main
                struct MyApp: App {
                  init() {
                    prepareDependencies {
                      FirebaseApp.configure()
                      $0.defaultFirestore = Firestore.firestore()
                    }
                  }

                  // ...
                }
            """
        }
      }
      reportIssue(message)
      let options = FirebaseOptions(googleAppID: "1:123:ios:123abc", gcmSenderID: "123")
      options.projectID = "demo-project"
      FirebaseApp.configure(options: options)
      Firestore.enableLogging(true)
      let settings = Firestore.firestore().settings
      let gcsettings = MemoryLRUGCSettings(sizeBytes: 100 * 1024 * 1024 as NSNumber)
      settings.cacheSettings = MemoryCacheSettings(garbageCollectorSettings: gcsettings)
      settings.host = "127.0.0.1:8080"
      settings.isSSLEnabled = false
      Firestore.firestore().settings = settings
      return Firestore.firestore()
    }
  }
}
