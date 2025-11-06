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
    var configuration: SharingFirestoreQuery.Configuration<Value>? { get }
    func query(_ db: Firestore) throws -> FirebaseFirestore.Query?
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
    guard let configuration else { return query }
    var query = query
    let filters = configuration.predicates.compactMap(convertFilter(predicates:))
    query = query.whereFilter(.andFilter(filters))
    query = convertQuery(base: query, predicates: configuration.predicates)
    return query
  }
}

private func convertFilter(predicates: SharingQueryPredicates) -> FirebaseFirestore.Filter? {
  switch predicates {
  case let .isEqualTo(field, value):
    let path = FieldPath(field.split(separator: ".").map(String.init))
    return Filter.whereField(path, isEqualTo: value.swiftValue)
  case let .isNotEqualTo(field, value):
    let path = FieldPath(field.split(separator: ".").map(String.init))
    return Filter.whereField(path, isNotEqualTo: value.swiftValue)
  case let .isIn(field, values):
    let path = FieldPath(field.split(separator: ".").map(String.init))
    return Filter.whereField(path, in: values.map(\.swiftValue))
  case let .isNotIn(field, values):
    let path = FieldPath(field.split(separator: ".").map(String.init))
    return Filter.whereField(path, notIn: values.map(\.swiftValue))
  case let .arrayContains(field, value):
    let path = FieldPath(field.split(separator: ".").map(String.init))
    return Filter.whereField(path, arrayContains: value.swiftValue)
  case let .arrayContainsAny(field, values):
    let path = FieldPath(field.split(separator: ".").map(String.init))
    return Filter.whereField(path, arrayContainsAny: values.map(\.swiftValue))
  case let .isLessThan(field, value):
    let path = FieldPath(field.split(separator: ".").map(String.init))
    return Filter.whereField(path, isLessThan: value.swiftValue)
  case let .isGreaterThan(field, value):
    let path = FieldPath(field.split(separator: ".").map(String.init))
    return Filter.whereField(path, isGreaterThan: value.swiftValue)
  case let .isLessThanOrEqualTo(field, value):
    let path = FieldPath(field.split(separator: ".").map(String.init))
    return Filter.whereField(path, isLessThanOrEqualTo: value.swiftValue)
  case let .isGreaterThanOrEqualTo(field, value):
    let path = FieldPath(field.split(separator: ".").map(String.init))
    return Filter.whereField(path, isGreaterOrEqualTo: value.swiftValue)
  case let .and(predicates):
    let andFilters = predicates.compactMap(convertFilter(predicates:))
    return Filter.andFilter(andFilters)
  case let .or(predicates):
    let orFilters = predicates.compactMap(convertFilter(predicates:))
    return Filter.orFilter(orFilters)
  case .orderBy, .limitTo, .limitToLast:
    return nil
  }
}

private func convertQuery(
  base: FirebaseFirestore.Query,
  predicates: [SharingQueryPredicates]
) -> FirebaseFirestore.Query {
  var query = base
  for predicate in predicates {
    switch predicate {
    case let .orderBy(field, isDesc):
      let path = FieldPath(field.split(separator: ".").map(String.init))
      query = query.order(by: path, descending: isDesc)
    case let .limitTo(count):
      query = query.limit(to: count)
    case let .limitToLast(count):
      query = query.limit(toLast: count)
    default:
      continue
    }
  }
  return query
}

extension SharingFirestoreQuery {
  /// A type defining the configuration for a Firestore query.
  public struct Configuration<ReturnValue: Decodable & Sendable>: Hashable, Sendable {
    public typealias TestingValues = RangeReplaceableCollection<ReturnValue> & Sendable
    /// The query's collection path.
    public var path: String

    /// The query's predicates.
    public var predicates: [SharingQueryPredicates]

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
        predicates: [SharingQueryPredicates] = [],
        source: FirestoreSource = .default,
        testingValue: (any TestingValues)? = nil,
        animation: Animation? = nil
      ) {
        self.path = path
        self.predicates = predicates
        self.source = source
        self.testingValue = testingValue
        self.animation = animation
      }
    #else
      public init(
        path: String,
        predicates: [SharingQueryPredicates] = [],
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
      lhs.path == rhs.path
        && lhs.predicates == rhs.predicates
        && lhs.source == rhs.source
    }

    public func hash(into hasher: inout Hasher) {
      hasher.combine(path)
      hasher.combine(predicates)
      hasher.combine(source)
    }
  }
}
