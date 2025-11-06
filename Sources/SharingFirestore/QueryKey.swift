import Dependencies
import Dispatch
@preconcurrency import FirebaseAuth
@preconcurrency import FirebaseFirestore
import IdentifiedCollections
import Sharing

#if canImport(Combine)
  @preconcurrency import Combine
#endif

#if canImport(SwiftUI)
  import SwiftUI
#endif

extension SharedReaderKey {
  /// A key that can query for a collection of data in a Firestore.
  ///
  /// A version of ``Sharing/SharedReaderKey/query(_:database:)`` that allows you to omit the
  /// type and default from the `@SharedReader` property wrapper:
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
  ///
  /// @SharedReader(.query(FactFetch()))
  /// private var facts: [Fact] = []
  /// ```
  ///
  /// See ``Sharing/SharedReaderKey/query(_:database:)`` for more info on how to use this API.
  ///
  /// - Parameters:
  ///   - request: A request describing the data to fetch.
  ///   - database: The database to read from. A value of `nil` will use the
  ///     ``Dependencies/DependencyValues/defaultFirestore``.
  /// - Returns: A key that can be passed to the `@SharedReader` property wrapper.
  public static func query<Records: RangeReplaceableCollection & Sendable>(
    _ request: some SharingFirestoreQuery.KeyRequest<Records.Element>,
    database: Firestore? = nil
  ) -> Self
  where Self == QueryKey<Records>.Default {
    Self[QueryKey(request: request, database: database), default: Value()]
  }

  /// A key that can query for a collection of data in a Firestore database.
  ///
  ///
  /// ```swift
  /// @SharedReader(
  ///   .query(
  ///     configuration: .init(
  ///       path: "facts",
  ///       predicates: [
  ///         .isEqualTo("trust", true),
  ///         .order(by: "count", descending: true),
  ///       ],
  ///       animation: .default
  ///     )
  ///   )
  /// )
  /// private var facts: IdentifiedArrayOf<Fact>
  /// ```
  ///
  /// For more complex querying needs, see ``Sharing/SharedReaderKey/query(_:database:)``.
  ///
  /// - Parameters:
  ///   - configuration: A value of firestore query configuration.
  ///   - database: The database to read from. A value of `nil` will use the
  ///     ``Dependencies/DependencyValues/defaultFirestore``.
  /// - Returns: A key that can be passed to the `@SharedReader` property wrapper.
  ///
  public static func query<Value: Decodable & Sendable>(
    configuration: SharingFirestoreQuery.Configuration<Value>,
    database: Firestore? = nil
  ) -> Self
  where Self == QueryKey<IdentifiedArrayOf<Value>>.Default {
    Self[
      QueryKey(
        request: FetchQueryConfigurationRequest(configuration: configuration),
        database: database
      ),
      default: []
    ]
  }

  /// A key that can query for a collection of data in a Firestore database.
  ///
  /// ```swift
  /// @SharedReader(
  ///   .query(
  ///     configuration: .init(
  ///       path: "facts",
  ///       predicates: [
  ///         .isEqualTo("trust", true),
  ///         .order(by: "count", descending: true),
  ///       ],
  ///       animation: .default
  ///     )
  ///   )
  /// )
  /// private var facts: [Fact]
  /// ```
  ///
  /// For more complex querying needs, see ``Sharing/SharedReaderKey/query(_:database:)``.
  ///
  /// - Parameters:
  ///   - configuration: A value of firestore query configuration.
  ///   - database: The database to read from. A value of `nil` will use the
  ///     ``Dependencies/DependencyValues/defaultFirestore``.
  /// - Returns: A key that can be passed to the `@SharedReader` property wrapper.
  ///
  public static func query<Value: Decodable & Sendable>(
    configuration: SharingFirestoreQuery.Configuration<Value>,
    database: Firestore? = nil
  ) -> Self
  where Self == QueryKey<[Value]>.Default {
    Self[
      QueryKey(
        request: FetchQueryConfigurationRequest(configuration: configuration),
        database: database
      ),
      default: []
    ]
  }
}

/// A type defining a reader of Firestore queries.
///
/// You typically do not refer to this type directly, and will use
/// [`query with request`](<doc:Sharing/SharedReaderKey/query(_:database:)>),
/// [`query array with configuration`](<doc:Sharing/SharedReaderKey/query(configuration:database:)-97g3u>), and
/// [`query identified array with configuration`](<doc:Sharing/SharedReaderKey/query(configuration:database:)-4sa1>) to create instances,
/// instead.
public struct QueryKey<Value: RangeReplaceableCollection & Sendable>: SharedReaderKey
where Value.Element: Decodable & Sendable {
  typealias Element = Value.Element
  let database: Firestore
  let request: any SharingFirestoreQuery.KeyRequest<Element>

  public typealias ID = UniqueRequestKeyID

  public var id: ID {
    ID(database: database, request: request)
  }

  init(
    request: some SharingFirestoreQuery.KeyRequest<Element>,
    database: Firestore? = nil
  ) {
    @Dependency(\.defaultFirestore) var defaultDatabase
    self.database = database ?? defaultDatabase
    self.request = request
  }

  func withResume(_ action: () -> Void) {
    #if canImport(SwiftUI)
      withAnimation(request.configuration?.animation) {
        action()
      }
    #else
      action()
    #endif
  }

  public func load(context: LoadContext<Value>, continuation: LoadContinuation<Value>) {
    guard case .userInitiated = context, let configuration = request.configuration else {
      continuation.resumeReturningInitialValue()
      return
    }
    guard !isTesting else {
      if let testingValue = configuration.testingValue {
        withResume {
          continuation.resume(returning: Value(testingValue))
        }
      } else {
        withResume {
          continuation.resumeReturningInitialValue()
        }
      }
      return
    }
    guard
      Auth.auth(app: database.app).currentUser != nil,
      let query = try? request.query(database)
    else {
      withResume {
        continuation.resumeReturningInitialValue()
      }
      return
    }
    Task {
      do {
        let source = configuration.source
        let snapshot = try await query.getDocuments(source: source)
        let values = snapshot.documents.compactMap {
          try? $0.data(as: Element.self)
        }
        withResume {
          continuation.resume(returning: Value(values))
        }
      } catch {
        withResume {
          continuation.resume(throwing: error)
        }
      }
    }
  }

  public func subscribe(
    context: LoadContext<Value>, subscriber: SharedSubscriber<Value>
  ) -> SharedSubscription {
    var snapshotRegistration: (any ListenerRegistration)? = nil
    let authListenerRegistration = Auth.auth(app: database.app).addStateDidChangeListener {
      _, user in
      if user != nil {
        if let query = try? request.query(database) {
          let registration = query.addSnapshotListener { snapshot, error in
            if let error {
              withResume {
                subscriber.yield(throwing: error)
              }
              return
            }
            guard let snapshot = snapshot else {
              withResume {
                subscriber.yieldReturningInitialValue()
              }
              return
            }
            let values = snapshot.documents.compactMap {
              return try? $0.data(as: Element.self)
            }
            withResume {
              subscriber.yield(Value(values))
            }
          }
          snapshotRegistration = registration
        }
      } else {
        snapshotRegistration?.remove()
      }
    }
    let task = Task {
      // authListenerRegistration自体をSendすることはできない
      // なのでTaskをsendして終了時にはcancelを呼び出すことで
      // sleepを抜けてremove処理を実行するようにスケジュールする
      try? await Task.sleep(nanoseconds: .max)
      snapshotRegistration?.remove()
      Auth
        .auth(app: database.app)
        .removeStateDidChangeListener(authListenerRegistration)
    }
    return SharedSubscription {
      task.cancel()
    }
  }
}

private struct FetchQueryConfigurationRequest<Element: Decodable & Sendable>: SharingFirestoreQuery
    .KeyRequest
{

  internal init(
    configuration: SharingFirestoreQuery.Configuration<Element>
  ) {
    self.configuration = configuration
  }

  internal var configuration: SharingFirestoreQuery.Configuration<Element>?

  internal func query(_ db: Firestore) throws -> Query? {
    guard let config = self.configuration else { return nil }
    var query: Query = db.collection(config.path)
    query = applingPredicated(query)
    return query
  }
}

private struct NotFound: Error {}
