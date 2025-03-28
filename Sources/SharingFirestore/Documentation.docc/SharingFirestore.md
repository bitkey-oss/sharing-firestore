# ``SharingFirestore``

## Overview

SharingFirestore is lightweight wrapper for Firebase's Firestore that integrates with the Sharing library, working across iOS 13, macOS 10.15, tvOS 13, watchOS 7 and newer.

@Row {
  @Column {
    ```swift
    // SharingFirestore
    @SharedReader(
      .query(
        configuration: .init(
          path: "facts",
          predicates: [.order(by: "count", descending: true)],
          animation: .default
        )
      )
    )
    var facts: IdentifiedArrayOf<Fact>
    ```
  }
  @Column {
    ```swift
    // Firestore
    database
      .collection("facts")
      .order(by: "count", descending: true)
      .addSnapshotListener { snapshot, error in
        // Handle data updates manually
      }
    ```
  }
}

Both of the above examples fetch items from Firestore, but SharingFirestore automatically observes changes so that when data changes it re-renders the view, and is usable from SwiftUI, UIKit, `@Observable` models, and more.

> Note: SharingFirestore provides both querying (read-only) and syncing (read-write) capabilities for Firestore collections and documents. See <doc:Fetching> and <doc:Syncing> for more information.

## Quick start

Before SharingFirestore's property wrappers can interact with Firestore, you need to provide—at
runtime—the default Firestore instance it should use. This is typically done as early as possible in your
app's lifetime, like the app entry point in SwiftUI:

```swift
// SharingFirestore
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
```

> Note: For more information on preparing Firestore, see <doc:PreparingDatabase>.

This `defaultFirestore` connection is used implicitly by SharingFirestore's strategies, like
[`query`](<doc:Sharing/SharedReaderKey/query(configuration:database:)-4sa1>) for read-only access:

```swift
@SharedReader(
  .query(
    configuration: .init(
      path: "facts",
      predicates: [.order(by: "count", descending: true)],
      animation: .default
    )
  )
)
private var facts: IdentifiedArrayOf<Fact>
```

And [`sync`](<doc:Sharing/SharedReaderKey/sync(configuration:database:)-3c82j>) for read-write access:

```swift
@Shared(
  .sync(
    configuration: .init(
      collectionPath: "todos",
      orderBy: ("createdAt", true),
      animation: .default
    )
  )
)
private var todos: IdentifiedArrayOf<Todo>
```

And you can access the Firestore database throughout your application using the dependency system:

@Row {
  @Column {
    ```swift
    // SharingFirestore
    @Dependency(\.defaultFirestore) var database

    try database.collection("todos").addDocument(from: Todo(
      memo: "New todo",
      completed: false
    ))
    ```
  }
  @Column {
    ```swift
    // Firestore
    let database = Firestore.firestore()

    try database.collection("todos").addDocument(from: Todo(
      memo: "New todo",
      completed: false
    ))
    ```
  }
}

This is all you need to know to get started with SharingFirestore, but there's much more to learn. Read
the articles below to learn how to best utilize this library.

## What is Sharing?

[Sharing](https://github.com/pointfreeco/swift-sharing) is a universal and extensible solution for
sharing your app's model data across features and with external systems, such as user defaults,
the file system, and more. This library builds upon the tools from Sharing in order to allow
[querying](<doc:Fetching>) and [syncing](<doc:Syncing>) data with Firestore.

This is all you need to know about Sharing to hit the ground running with SharingFirestore, but it only
scratches the surface of what the library makes possible. To learn more, check out
[the Sharing documentation](https://swiftpackageindex.com/pointfreeco/swift-sharing/main/documentation/sharing/).

## What is Firestore?

[Firestore](https://firebase.google.com/docs/firestore) is Google's flexible, scalable NoSQL cloud database
that lets you store and sync data for client and server-side development. It offers real-time updates, offline support,
and powerful querying capabilities.

SharingFirestore leverages Firestore's document-based model and observation APIs to keep the `@SharedReader` and `@Shared`
property wrappers in sync with the database and update SwiftUI views automatically.

## Topics

### Essentials

- <doc:Fetching>
- <doc:Syncing>
- <doc:Observing>
- <doc:PreparingDatabase>
- <doc:DynamicQueries>

### Database configuration and access

- ``Dependencies/DependencyValues/defaultFirestore``

### Fetch strategies

- ``Sharing/SharedReaderKey/query(_:database:)``
- ``Sharing/SharedReaderKey/query(configuration:database:)``

### Sync strategies

- ``Sharing/SharedReaderKey/sync(_:database:)``
- ``Sharing/SharedReaderKey/sync(configuration:database:)``
