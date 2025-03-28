# Syncing model data

Syncing data between your app and Firestore.

## Overview

Unlike the `query` API which is read-only, SharingFirestore's `sync` API allows for bidirectional data flow - both reading from and writing to Firestore. This is particularly useful for collaborative features where multiple users or devices need to share and modify the same data.

  * [Syncing collections](#Syncing-collections)
  * [Syncing single documents](#Syncing-single-documents)
  * [Custom sync requests](#Custom-sync-requests)
  * [Working with DocumentIdentifiable](#Working-with-DocumentIdentifiable)

### Syncing collections

To sync a collection of documents with Firestore, use the `sync` key with a collection configuration:

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

This creates a bidirectional connection to the "todos" collection in Firestore:
- Changes from Firestore are automatically reflected in your app
- Modifications to the local `todos` property are persisted back to Firestore

You can modify the collection using SwiftUI bindings or directly:

```swift
// Add a new todo
$todos.withLock {
  $0.insert(Todo(memo: "New task", completed: false), at: 0)
}

// Delete a todo
$todos.withLock {
  _ = $0.remove(id: someTodo.id)
}

// Update a todo
$todos.withLock {
  if let index = $0.firstIndex(where: { $0.id == someTodo.id }) {
    $0[index].completed.toggle()
  }
}
```

### Syncing single documents

For syncing a single document, use the `sync` key with a document configuration:

```swift
@Shared(
  .sync(
    configuration: .init(
      collectionPath: "settings",
      documentId: "user-preferences",
      animation: .default
    )
  )
)
private var settings: UserSettings = UserSettings() // Default value
```

This establishes a connection to a specific document in Firestore. Any changes to the local `settings` property are synchronized back to Firestore:

```swift
// Update settings locally, which will sync to Firestore
settings.darkMode = true
settings.notificationsEnabled = false
```

### Custom sync requests

For more advanced syncing needs, you can create custom sync requests:

```swift
struct UserTodos: SharingFirestoreSync.KeyCollectionRequest {
  typealias Value = Todo
  let userId: String

  var configuration: SharingFirestoreSync.CollectionConfiguration<Todo> {
    .init(
      collectionPath: "users/\(userId)/todos",
      orderBy: ("createdAt", true),
      animation: .default
    )
  }
}

@Shared(.sync(UserTodos(userId: currentUserId)))
private var userTodos: IdentifiedArrayOf<Todo>
```

For a single document:

```swift
struct UserProfile: SharingFirestoreSync.KeyDocumentRequest {
  typealias Value = Profile
  let userId: String

  var configuration: SharingFirestoreSync.DocumentConfiguration<Profile> {
    .init(
      collectionPath: "profiles",
      documentId: userId,
      animation: .default
    )
  }
}

@Shared(.sync(UserProfile(userId: currentUserId)))
private var profile: Profile = Profile() // Default value
```

### Working with DocumentIdentifiable

For models to work with the sync API, they need to conform to `DocumentIdentifiable`, which requires both a client-side ID and a Firestore document ID:

```swift
struct Todo: Codable, DocumentIdentifiable {
  // Required by DocumentIdentifiable
  var clientId: UUID = UUID()  // Local client ID
  @DocumentID var documentId: String?  // Firestore document ID

  // Your model properties
  var memo: String
  var completed: Bool
  var createdAt: Date = Date()
}
```

The `clientId` gives your model a stable identity within your app, which is needed for SwiftUI to correctly identify and track items, while the `documentId` maps to Firestore's document IDs.

When adding new items to a synced collection, SharingFirestore will:
1. Create new document IDs for items without a `documentId`
2. Update existing documents for items with a `documentId`
3. Delete documents from Firestore that aren't present in your local collection

### Testing considerations

You can provide test values for your sync configurations to use during testing:

```swift
let testTodos: [Todo] = [
  Todo(memo: "Test todo 1", completed: false),
  Todo(memo: "Test todo 2", completed: true)
]

@Shared(
  .sync(
    configuration: .init(
      collectionPath: "todos",
      orderBy: ("createdAt", true),
      testingValue: testTodos,  // Used during testing
      animation: .default
    )
  )
)
private var todos: IdentifiedArrayOf<Todo>
```

This allows you to develop and test your UI without requiring a real Firestore connection.
