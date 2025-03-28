@preconcurrency import FirebaseFirestore
import Sharing

#if canImport(SwiftUI)
  import SwiftUI
#endif

/// A type that provide namespace.
public enum SharingFirestoreQuery {}

extension SharingFirestoreQuery {
  /// A type that can request a value from a database.
  ///
  /// This type can be used to describe a query to read data from Firestore:
  ///
  /// ```swift
  /// private struct FactFetch: SharingFirestoreQuery.KeyRequest {
  ///   let configuration = SharingFirestoreQuery.Configuration<Fact>(
  ///     path: "/facts",
  ///     predicates: [
  ///       .order(by: "count", descending: true),
  ///     ],
  ///     animation: .default
  ///   )
  ///
  ///   func query(_ db: Firestore) throws -> Query {
  ///     let ref = db.collection(configuration.path)
  ///     let query = applingPredicated(ref)
  ///     return query.limit(to: 3)
  ///   }
  /// }
  /// ```
  ///
  /// And then can be used with `@SharedReader` and
  /// ``Sharing/SharedReaderKey/query(_:database:)`` to popular state with the query
  /// in a SwiftUI view, `@Observable` model, UIKit controller, and more:
  ///
  /// ```swift
  /// struct PlayersView: View {
  ///   @SharedReader(.query(FactFetch())) private var facts: [Fact]
  ///
  ///   var body: some View {
  ///     ForEach(facts) { fact in
  ///       // ...
  ///     }
  ///   }
  /// }
  /// ```
  public protocol KeyRequest<Value>: Hashable, Sendable {
    associatedtype Value: Decodable & Sendable
    var configuration: SharingFirestoreQuery.Configuration<Value> { get }
    func query(_ db: Firestore) throws -> FirebaseFirestore.Query
  }
}

extension SharingFirestoreQuery.KeyRequest {
  /// A function that can apply firestore query of configuration for firestore.
  ///
  /// This is a utility for composing Firestore queries when creating custom queries:
  ///
  /// ```swift
  /// private struct FactFetch: SharingFirestoreQuery.KeyRequest {
  ///   let configuration = SharingFirestoreQuery.Configuration<Fact>(
  ///     path: "/facts",
  ///     predicates: [
  ///       .order(by: "count", descending: true),
  ///     ],
  ///     animation: .default
  ///   )
  ///
  ///   func query(_ db: Firestore) throws -> Query {
  ///     let ref = db.collection(configuration.path)
  ///     let query = applingPredicated(ref)
  ///     return query.limit(to: 3)
  ///   }
  /// }
  /// ```
  public func applingPredicated(_ query: FirebaseFirestore.Query) -> FirebaseFirestore.Query {
    var query = query
    for predicate in self.configuration.predicates {
      switch predicate {
      case let .isEqualTo(field, value):
        query = query.whereField(field, isEqualTo: value)
      case let .isIn(field, values):
        query = query.whereField(field, in: values)
      case let .isNotIn(field, values):
        query = query.whereField(field, notIn: values)
      case let .arrayContains(field, value):
        query = query.whereField(field, arrayContains: value)
      case let .arrayContainsAny(field, values):
        query = query.whereField(field, arrayContainsAny: values)
      case let .isLessThan(field, value):
        query = query.whereField(field, isLessThan: value)
      case let .isGreaterThan(field, value):
        query = query.whereField(field, isGreaterThan: value)
      case let .isLessThanOrEqualTo(field, value):
        query = query.whereField(field, isLessThanOrEqualTo: value)
      case let .isGreaterThanOrEqualTo(field, value):
        query = query.whereField(field, isGreaterThanOrEqualTo: value)
      case let .orderBy(field, value):
        query = query.order(by: field, descending: value)
      case let .limitTo(field):
        query = query.limit(to: field)
      case let .limitToLast(field):
        query = query.limit(toLast: field)
      }
    }
    return query
  }
}

extension SharingFirestoreQuery {
  /// A type defining the configuration for a Firestore query.
  public struct Configuration<ReturnValue: Decodable & Sendable>: Hashable, Sendable {
    public typealias TestingValues = RangeReplaceableCollection<ReturnValue> & Sendable
    /// The query's collection path.
    public var path: String

    /// The query's predicates.
    public var predicates: [QueryPredicate]

    /// The query's hash value.
    public var predicatesHashValue: Int

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
        path: String,
        predicates: [QueryPredicate] = [],
        predicatesHashValue: Int? = nil,
        source: FirestoreSource = .default,
        testingValue: (any TestingValues)? = nil,
        animation: Animation? = nil
      ) {
        self.path = path
        self.predicates = predicates
        self.predicatesHashValue = predicatesHashValue ?? 0
        self.source = source
        self.testingValue = testingValue
        self.animation = animation
      }
    #else
      public init(
        path: String,
        predicates: [QueryPredicate] = [],
        predicatesHashValue: Int? = nil,
        source: FirestoreSource = .default,
        testingValue: ReturnValue? = nil
      ) {
        self.path = path
        self.predicates = predicates
        self.predicatesHashValue = predicatesHashValue ?? 0
        self.source = source
        self.testingValue = testingValue
      }
    #endif

    public static func == (
      lhs: SharingFirestoreQuery.Configuration<ReturnValue>,
      rhs: SharingFirestoreQuery.Configuration<ReturnValue>
    ) -> Bool {
      lhs.path == rhs.path && lhs.predicatesHashValue == rhs.predicatesHashValue
    }

    public func hash(into hasher: inout Hasher) {
      hasher.combine(path)
      hasher.combine(predicatesHashValue)
    }
  }
}
