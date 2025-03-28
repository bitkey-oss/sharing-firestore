# Fetching Model Data

You can customize how data is queried from Firestore using various options.

## Overview

All data fetching happens by providing
[`query`](<doc:Sharing/SharedReaderKey/query(configuration:database:)>) to the `@SharedReader`
property wrapper. The primary ways to fetch data are either by using a predefined configuration or by creating a custom
query request.

  * [Querying with configuration](#Querying-with-configuration)
  * [Querying with a custom request](#Querying-with-a-custom-request)
  * [Using different query predicates](#Using-different-query-predicates)

### Querying with configuration

For most queries, the simplest approach is to use a configuration that defines how to fetch data from Firestore.
This allows you to specify the collection path and various predicates:

```swift
@SharedReader(
  .query(
    configuration: .init(
      path: "facts",
      predicates: [
        .order(by: "count", descending: true)
      ],
      animation: .default
    )
  )
)
var facts: IdentifiedArrayOf<Fact>
```

You can add filtering conditions to your query by adding predicates:

```swift
@SharedReader(
  .query(
    configuration: .init(
      path: "todos",
      predicates: [
        .isEqualTo("completed", true),
        .order(by: "createdAt", descending: true)
      ],
      animation: .default
    )
  )
)
var completedTodos: IdentifiedArrayOf<Todo>
```

### Querying with a custom request

For more complex queries, you can create a custom request by conforming to `SharingFirestoreQuery.KeyRequest`.
This gives you full access to Firestore's query capabilities:

```swift
private struct FactFetch: SharingFirestoreQuery.KeyRequest {
  let configuration = SharingFirestoreQuery.Configuration<Fact>(
    path: "facts",
    predicates: [
      .order(by: "count", descending: true)
    ],
    animation: .default
  )

  func query(_ db: Firestore) throws -> Query {
    let ref = db.collection(configuration.path)
    let query = applingPredicated(ref)
    return query.limit(to: 3)  // Add custom limit
  }
}

@SharedReader(.query(FactFetch()))
private var facts: [Fact]
```

This approach is useful when you need to add advanced query logic or constraints beyond what the
standard predicates offer.

### Using different query predicates

SharingFirestore supports a wide range of Firestore query predicates through the `QueryPredicate` type:

* `.isEqualTo(field, value)`: Filter documents where field equals value
* `.isIn(field, values)`: Filter documents where field value is in a collection of values
* `.isNotIn(field, values)`: Filter documents where field value is not in a collection of values
* `.arrayContains(field, value)`: Filter documents where array field contains value
* `.arrayContainsAny(field, values)`: Filter documents where array field contains any value from values
* `.isLessThan(field, value)`: Filter documents where field is less than value
* `.isGreaterThan(field, value)`: Filter documents where field is greater than value
* `.isLessThanOrEqualTo(field, value)`: Filter documents where field is less than or equal to value
* `.isGreaterThanOrEqualTo(field, value)`: Filter documents where field is greater than or equal to value
* `.orderBy(field, descending)`: Order results by field in ascending or descending order
* `.limitTo(count)`: Limit results to the first count documents
* `.limitToLast(count)`: Limit results to the last count documents

Here's an example that combines multiple predicates:

```swift
@SharedReader(
  .query(
    configuration: .init(
      path: "products",
      predicates: [
        .isGreaterThanOrEqualTo("price", 10.0),
        .isLessThan("price", 50.0),
        .isEqualTo("inStock", true),
        .order(by: "price", descending: false)
      ],
      animation: .default
    )
  )
)
var affordableProducts: [Product]
```

### Model Types

For your model types to work with SharingFirestore, they need to conform to `Decodable` (for reading)
and optionally `Identifiable` for use with SwiftUI lists and other collection views:

```swift
struct Fact: Decodable, Identifiable {
  @DocumentID var id: String?
  var count: Int
  var body: String
}
```

Or for read-write operations with the sync API, you'll need to implement `DocumentIdentifiable`:

```swift
struct Todo: Codable, DocumentIdentifiable {
  var clientId: UUID = UUID()
  @DocumentID var documentId: String?
  var memo: String
  var completed: Bool
  var createdAt: Date = Date()
}
```

The `@DocumentID` property wrapper automatically handles Firestore's document IDs, mapping them to
your model's property.
