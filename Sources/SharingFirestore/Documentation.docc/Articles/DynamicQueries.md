# Dynamic Queries

Your app adapts its fetch queries dynamically as the user modifies input parameters

## Overview

In many applications, you need to adapt your Firestore queries based on user input or changing conditions - such as implementing search functionality, applying filters, or changing sort order. SharingFirestore provides tools to handle these dynamic querying scenarios.

### The problem with static queries and client-side filtering

Using a `static` query to fetch all data upfront and filter it in Swift is inefficient, since it loads more data than needed and puts unnecessary processing on the client.

```swift
struct ContentView: View {
  @SharedReader(
    .query(
      configuration: .init(
        path: "items",
        animation: .default
      )
    )
  )
  var allItems: [Item]
  @State var searchText = ""
  @State var filterCategory: Category?

  // Inefficient - filters all items in memory after fetching everything
  var filteredItems: [Item] {
    allItems
      .filter { item in
        (searchText.isEmpty || item.name.localizedCaseInsensitiveContains(searchText)) &&
        (filterCategory == nil || item.category == filterCategory)
      }
      .sorted { $0.createdAt > $1.createdAt }
      .prefix(20)
  }

  // View implementation...
}
```

This approach has several disadvantages:
1. You download all documents, even those that don't match your criteria
2. Client-side filtering consumes device CPU and memory
3. The filtering is re-run every time the view body is evaluated
4. You're limited by the data you've already fetched

### Dynamic queries with state management

SharingFirestore allows you to reload queries with new parameters using the `load` method:

```swift
struct SearchableItemsView: View {
  @State.SharedReader(value: []) var items: [Item]
  @State private var searchText = ""
  @State private var selectedCategory: Category?

  var body: some View {
    VStack {
      SearchBar(text: $searchText)

      CategoryPicker(selectedCategory: $selectedCategory)

      List {
        ForEach(items) { item in
          ItemRow(item: item)
        }
      }
    }
    .task(id: searchCriteria) {
      await updateQuery()
    }
  }

  private var searchCriteria: (String, Category?) {
    (searchText, selectedCategory)
  }

  private func updateQuery() async {
    do {
      try await $items.load(.query(ItemQuery(
        searchText: searchText,
        category: selectedCategory
      )))
    } catch {
      // Handle error
    }
  }

  private struct ItemQuery: SharingFirestoreQuery.KeyRequest {
    let searchText: String
    let category: Category?

    var configuration: SharingFirestoreQuery.Configuration<Item> {
      .init(
        path: "items",
        // We don't include search predicates here because they're applied in the query method
        animation: .default
      )
    }

    func query(_ db: Firestore) throws -> Query {
      var query = db.collection(configuration.path)

      if let category = category {
        query = query.whereField("category", isEqualTo: category.rawValue)
      }

      if !searchText.isEmpty {
        // Firestore doesn't support native full-text search, so we might use:
        // 1. Field-specific contains search (with limitations)
        query = query.whereField("name", isGreaterThanOrEqualTo: searchText)
                     .whereField("name", isLessThanOrEqualTo: searchText + "\u{f8ff}")

        // Or for production, consider:
        // 2. Multiple field exact matches for keywords
        // 3. Integration with tools like Algolia or ElasticSearch
      }

      // Apply ordering and limit
      query = query.order(by: "createdAt", descending: true).limit(to: 20)

      return query
    }
  }
}
```

> Important: Note the use of `@State.SharedReader` instead of `@SharedReader`. This wraps the property in SwiftUI's `@State`, ensuring that the query state is maintained locally within the view and not overwritten if the parent view refreshes.

> Note: Firestore's text search capabilities are limited. For basic prefix search, you can use the range query technique shown above. For more sophisticated search, consider using a dedicated search service like Algolia or Elastic, or implementing keyword-based search with arrays of terms.

### Handling advanced search patterns

If your app requires more complex search, you may need to design your data model specifically to support the query patterns you need. Here are some common approaches:

1. **Keyword arrays**: Store an array of lowercase keywords for each document that can be searched with `arrayContainsAny`

```swift
struct KeywordSearchQuery: SharingFirestoreQuery.KeyRequest {
  let keywords: [String]

  var configuration: SharingFirestoreQuery.Configuration<Product> {
    .init(path: "products", animation: .default)
  }

  func query(_ db: Firestore) throws -> Query {
    // Limit Firestore's arrayContainsAny to 10 values
    let limitedKeywords = Array(keywords.prefix(10))

    var query = db.collection(configuration.path)

    if !limitedKeywords.isEmpty {
      query = query.whereField("searchKeywords", arrayContainsAny: limitedKeywords)
    }

    return query.limit(to: 20)
  }
}
```

2. **Subcollection filtering**: For hierarchical data, use sub-collections and dynamic path construction

```swift
struct UserItemsQuery: SharingFirestoreQuery.KeyRequest {
  let userId: String
  let status: ItemStatus?

  var configuration: SharingFirestoreQuery.Configuration<Item> {
    .init(
      path: "users/\(userId)/items",
      animation: .default
    )
  }

  func query(_ db: Firestore) throws -> Query {
    var query = db.collection(configuration.path)

    if let status = status {
      query = query.whereField("status", isEqualTo: status.rawValue)
    }

    return query.order(by: "updatedAt", descending: true)
  }
}
```

### Reacting to external changes

You can also update queries in response to external events or state changes:

```swift
struct StoreView: View {
  @ObservedObject var locationManager: LocationManager
  @State.SharedReader(value: []) var nearbyStores: [Store]

  var body: some View {
    List {
      ForEach(nearbyStores) { store in
        StoreRow(store: store)
      }
    }
    .onReceive(locationManager.$currentLocation) { location in
      Task {
        if let location = location {
          try? await $nearbyStores.load(.query(
            NearbyStoresQuery(
              latitude: location.coordinate.latitude,
              longitude: location.coordinate.longitude,
              radiusKm: 10
            )
          ))
        }
      }
    }
  }
}
```

### Performance considerations

When implementing dynamic queries, keep these performance tips in mind:

1. Set appropriate limits on result sizes
2. Cache results when appropriate
3. Consider using Firestore query cursors for pagination
4. Add indexes for fields used in compound queries
5. Be mindful of Firestore's query limitations (e.g., range filters can only be applied to one field)
6. For full-text search features, consider integrating an external search service
