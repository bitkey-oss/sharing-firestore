# SharingFirestore

A lightweight wrapper for Firebase's Firestore database that integrates with the Sharing library.

A swift library that extends the [swift-sharing](https://github.com/pointfreeco/swift-sharing) library with support for Firebase's Firestore.

* [Learn more](#Learn-more)
* [Overview](#Overview)
* [Demos](#Demos)
* [Documentation](#Documentation)
* [Installation](#Installation)
* [License](#License)

## Overview

SharingFirestore is a lightweight wrapper for working with Firebase's Firestore via the Sharing library.

By integrating with Sharing, you can combine Firestore's powerful real-time database capabilities with Sharing's powerful observation functions. You can synchronize data across devices with the ease of UserDefaults, and you can keep your UI updated in real-time, similar to how SwiftUI's @Observable works.

This project is inspired by [SharingGRDB](https://github.com/pointfreeco/sharing-grdb) and provides a convenient wrapper for using Firestore in SwiftUI and UIKit applications. Thanks to pointfreeco for publishing this great library.

## Quick start

Before SharingFirestore's property wrappers can fetch data from Firestore, you need to provide—at
runtime—the default Firestore instance it should use. This is typically done as early as possible in your
app's lifetime, like the app entry point in SwiftUI:

```swift
import SharingFirestore
import SwiftUI

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

> Note: For more information on preparing Firestore, see
[Preparing Firestore][preparing-db-article].

This `defaultFirestore` connection is used implicitly by SharingFirestore's strategies:

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


And you can access the Firestore database throughout your application using the dependency system:

```swift
@Dependency(\.defaultFirestore)
var database

try database.collection("todos").addDocument(from: Todo(memo: "New todo", completed: false))
```

This is all you need to know to get started with SharingFirestore, but there's much more to learn. Read
the [articles][articles] below to learn how to best utilize this library:

* [Fetching model data][fetching-article]
* [Syncing model data][syncing-article]
* [Observing changes to model data][observing-article]
* [Preparing Firestore][preparing-db-article]
* [Dynamic queries][dynamic-queries-article]

[dynamic-queries-article]: https://swiftpackageindex.com/bitkey-oss/sharing-firestore/main/documentation/sharingfirestore/dynamicqueries
[articles]: https://swiftpackageindex.com/bitkey-oss/sharing-firestore/main/documentation/sharingfirestore#Essentials
[observing-article]: https://swiftpackageindex.com/bitkey-oss/sharing-firestore/main/documentation/sharingfirestore/observing
[fetching-article]: https://swiftpackageindex.com/bitkey-oss/sharing-firestore/main/documentation/sharingfirestore/fetching
[syncing-article]: https://swiftpackageindex.com/bitkey-oss/sharing-firestore/main/documentation/sharingfirestore/syncing
[preparing-db-article]: https://swiftpackageindex.com/bitkey-oss/sharing-firestore/main/documentation/sharingfirestore/preparingdatabase

## Demos

This repo comes with several examples to demonstrate how to solve common and complex problems with
SharingFirestore. Check out [this](./Examples) directory to see them all, including:

  * [Case Studies](./Examples/CaseStudies):
    A number of case studies demonstrating the built-in features of the library, including querying, syncing, dynamic queries, and integration with @Observable models.

## Documentation

The documentation for releases and `main` are available here:

* [`main`](https://swiftpackageindex.com/bitkey-oss/sharing-firestore/main/documentation/sharingfirestore/)

## Installation

You can add SharingFirestore to an Xcode project by adding it to your project as a package.

> https://github.com/bitkey-oss/sharing-firestore

If you want to use SharingFirestore in a [SwiftPM](https://swift.org/package-manager/) project, it's as
simple as adding it to your `Package.swift`:

``` swift
dependencies: [
  .package(url: "https://github.com/bitkey-oss/sharing-firestore", from: "0.1.0")
]
```

And then adding the products to any target that needs access to the libraries:

```swift
.product(name: "SharingFirestore", package: "sharing-firestore"),
```

## License

This library is released under the MIT license. See [LICENSE](LICENSE) for details.
