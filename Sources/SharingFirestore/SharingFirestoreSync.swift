import FirebaseFirestore
import Sharing

#if canImport(SwiftUI)
  import SwiftUI
#endif

public enum SharingFirestoreSync {}

extension SharingFirestoreSync {

  /// A struct representing field ordering in Firestore queries
  public struct OrderBy: Hashable, Sendable {
    /// The field name to order by
    public let field: String

    /// The sort order (ascending or descending)
    public let sortOrder: SortOrder

    var isDescending: Bool {
      sortOrder.isDescending
    }

    /// Creates an OrderBy with the specified field and sort order
    public init(field: String, sortOrder: SortOrder) {
      self.field = field
      self.sortOrder = sortOrder
    }

    /// Creates an OrderBy with the specified field in ascending order
    /// - Parameter field: The field name to order by
    /// - Returns: An OrderBy configured for ascending order
    public static func asc(_ field: String) -> OrderBy {
      OrderBy(field: field, sortOrder: .ascending)
    }

    /// Creates an OrderBy with the specified field in descending order
    /// - Parameter field: The field name to order by
    /// - Returns: An OrderBy configured for descending order
    public static func desc(_ field: String) -> OrderBy {
      OrderBy(field: field, sortOrder: .descending)
    }

    /// An enum representing sort order for Firestore queries
    public enum SortOrder: Hashable, Sendable {
      case ascending
      case descending

      var isDescending: Bool {
        switch self {
        case .ascending: return false
        case .descending: return true
        }
      }
    }
  }

  /// A type that can request a collection of values from a database.
  ///
  /// This type can be used to describe a query to read/write collection data from Firestore:
  ///
  /// ```swift
  /// struct Todos: SharingFirestoreSync.KeyCollectionRequest {
  ///   typealias Value = Todo
  ///
  ///   var configuration: SharingFirestoreSync.CollectionConfiguration<Todo> {
  ///     .init(
  ///       collectionPath: "todos",
  ///       orderBy: .desc("createdAt"),
  ///       animation: .default
  ///     )
  ///   }
  /// }
  /// ```
  ///
  /// And then can be used with `@Shared` and
  /// ``Sharing/SharedReaderKey/sync(_:database:)-385la`` to populate state with the query
  /// in a SwiftUI view, `@Observable` model, UIKit controller, and more:
  ///
  /// ```swift
  /// struct TodosView: View {
  ///   @Shared(.sync(Todos())) var todos: IdentifiedArrayOf<Todo>
  ///
  ///   var body: some View {
  ///     ForEach(todos) { todo in
  ///       // ...
  ///     }
  ///   }
  /// }
  /// ```
  public protocol KeyCollectionRequest<Value>: Hashable, Sendable {
    associatedtype Value: Codable & DocumentIdentifiable & Sendable
    var configuration: SharingFirestoreSync.CollectionConfiguration<Value> { get }
  }

  /// A type that can request a single document from a database.
  ///
  /// This type can be used to describe a query to read/write a single document from Firestore:
  ///
  /// ```swift
  /// struct UserProfile: SharingFirestoreSync.KeyDocumentRequest {
  ///   typealias Value = Profile
  ///   let userId: String
  ///
  ///   var configuration: SharingFirestoreSync.DocumentConfiguration<Profile> {
  ///     .init(
  ///       collectionPath: "profiles",
  ///       documentId: userId,
  ///       animation: .default
  ///     )
  ///   }
  /// }
  /// ```
  ///
  /// And then can be used with `@Shared` to populate state with the document:
  ///
  /// ```swift
  /// struct ProfileView: View {
  ///   @Shared(.sync(UserProfile(userId: currentUserId)))
  ///   private var profile: Profile = Profile() // Default value
  ///
  ///   var body: some View {
  ///     // Use profile properties
  ///   }
  /// }
  /// ```
  public protocol KeyDocumentRequest<Value>: Hashable, Sendable {
    associatedtype Value: Codable & Sendable
    var configuration: SharingFirestoreSync.DocumentConfiguration<Value> { get }
  }
}

extension SharingFirestoreSync {
  /// A type defining the configuration for a syncing Firestore collection.
  public struct CollectionConfiguration<ReturnValue: Codable & DocumentIdentifiable & Sendable>:
    Hashable, Sendable
  {
    public typealias TestingValues = RangeReplaceableCollection<ReturnValue> & Sendable
    /// The query's collection path.
    public var collectionPath: String

    /// The field to order by and the sort order.
    public var orderBy: SharingFirestoreSync.OrderBy?

    /// Source of the data.
    public var source: FirestoreSource = .default

    /// Provides a value for testing purposes.
    public var testingValue: (any TestingValues)?

    #if canImport(SwiftUI)
      /// The type of animation to apply when updating the view. If this is omitted then no
      /// animations are fired.
      public var animation: Animation?
    #endif

    #if canImport(SwiftUI)
      public init(
        collectionPath: String,
        orderBy: SharingFirestoreSync.OrderBy? = nil,
        source: FirestoreSource = .default,
        testingValue: (any TestingValues)? = nil,
        animation: Animation? = nil
      ) {
        self.collectionPath = collectionPath
        self.orderBy = orderBy
        self.source = source
        self.testingValue = testingValue
        self.animation = animation
      }
    #else
      public init(
        collectionPath: String,
        orderBy: SharingFirestoreSync.OrderBy? = nil,
        source: FirestoreSource = .default,
        testingValue: (any TestingValues)? = nil
      ) {
        self.collectionPath = collectionPath
        self.orderBy = orderBy
        self.source = source
        self.testingValue = testingValue
      }
    #endif

    /// Creates a collection configuration with the specified parameters.
    ///
    /// - Parameters:
    ///   - collectionPath: The path to the collection in Firestore
    ///   - orderBy: Optional field name and sort order for ordering the results
    ///   - source: Source of the data (.default, .cache, .server)
    ///   - testingValue: Optional values to use for testing
    ///   - animation: Optional animation to apply when updating the view
    /// - Returns: A new collection configuration
    #if canImport(SwiftUI)
      public static func collection(
        path: String,
        orderBy: SharingFirestoreSync.OrderBy? = nil,
        source: FirestoreSource = .default,
        testingValue: (any TestingValues)? = nil,
        animation: Animation? = nil
      ) -> Self {
        return .init(
          collectionPath: path,
          orderBy: orderBy,
          source: source,
          testingValue: testingValue,
          animation: animation
        )
      }
    #else
      public static func collection(
        path: String,
        orderBy: SharingFirestoreSync.OrderBy? = nil,
        source: FirestoreSource = .default,
        testingValue: (any TestingValues)? = nil
      ) -> Self {
        return .init(
          collectionPath: path,
          orderBy: orderBy,
          source: source,
          testingValue: testingValue
        )
      }
    #endif

    public static func == (
      lhs: SharingFirestoreSync.CollectionConfiguration<ReturnValue>,
      rhs: SharingFirestoreSync.CollectionConfiguration<ReturnValue>
    ) -> Bool {
      lhs.collectionPath == rhs.collectionPath
    }

    public func hash(into hasher: inout Hasher) {
      hasher.combine(collectionPath)
    }
  }

  /// A type defining the configuration for a syncing Firestore document.
  public struct DocumentConfiguration<ReturnValue: Codable & Sendable>: Hashable, Sendable {
    /// The query's collection path.
    public var collectionPath: String

    /// The query's document id.
    public var documentId: String

    /// Source of the data.
    public var source: FirestoreSource = .default

    /// Provides a value for testing purposes.
    public var testingValue: ReturnValue?

    #if canImport(SwiftUI)
      /// The type of animation to apply when updating the view. If this is omitted then no
      /// animations are fired.
      public var animation: Animation?
    #endif

    #if canImport(SwiftUI)
      public init(
        collectionPath: String,
        documentId: String,
        source: FirestoreSource = .default,
        testingValue: ReturnValue? = nil,
        animation: Animation? = nil
      ) {
        self.collectionPath = collectionPath
        self.documentId = documentId
        self.source = source
        self.testingValue = testingValue
        self.animation = animation
      }
    #else
      public init(
        collectionPath: String,
        documentId: String,
        source: FirestoreSource = .default,
        testingValue: ReturnValue? = nil
      ) {
        self.collectionPath = collectionPath
        self.documentId = documentId
        self.source = source
        self.testingValue = testingValue
      }
    #endif

    /// Creates a document configuration with the specified parameters.
    ///
    /// - Parameters:
    ///   - collectionPath: The path to the collection containing the document
    ///   - documentId: The ID of the document to sync
    ///   - source: Source of the data (.default, .cache, .server)
    ///   - testingValue: Optional value to use for testing
    ///   - animation: Optional animation to apply when updating the view
    /// - Returns: A new document configuration
    #if canImport(SwiftUI)
      public static func document(
        collectionPath: String,
        documentId: String,
        source: FirestoreSource = .default,
        testingValue: ReturnValue? = nil,
        animation: Animation? = nil
      ) -> Self {
        return .init(
          collectionPath: collectionPath,
          documentId: documentId,
          source: source,
          testingValue: testingValue,
          animation: animation
        )
      }
    #else
      public static func document(
        collectionPath: String,
        documentId: String,
        source: FirestoreSource = .default,
        testingValue: ReturnValue? = nil
      ) -> Self {
        return .init(
          collectionPath: collectionPath,
          documentId: documentId,
          source: source,
          testingValue: testingValue
        )
      }
    #endif

    public static func == (
      lhs: SharingFirestoreSync.DocumentConfiguration<ReturnValue>,
      rhs: SharingFirestoreSync.DocumentConfiguration<ReturnValue>
    ) -> Bool {
      lhs.collectionPath == rhs.collectionPath && lhs.documentId == rhs.documentId
    }

    public func hash(into hasher: inout Hasher) {
      hasher.combine(collectionPath)
      hasher.combine(documentId)
    }
  }
}
