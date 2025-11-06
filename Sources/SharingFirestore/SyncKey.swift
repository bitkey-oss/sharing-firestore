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

  /// A key that can sync for collection data in a Firestore database.
  ///
  /// This key takes a ``SharingFirestoreSync/KeyCollectionRequest`` conformance, which you define yourself. It has a single
  /// requirement that describes syncing a value from a database connection. For examples, we can
  /// define an `Todos` request that uses Firestore's query builder to fetch some items:
  ///
  /// ```swift
  /// private struct Todos: SharingFirestoreSync.KeyCollectionRequest {
  ///   typealias Value = Todo
  ///   let configuration: SharingFirestoreSync.CollectionConfiguration<Value> = .init(
  ///     collectionPath: "todos",
  ///     orderBy: .desc("createdAt"),
  ///     animation: .default
  ///   )
  /// }
  /// ```
  ///
  /// And one can query for this data by wrapping the request in this key and provide it to the
  /// `@Shared` property wrapper:
  ///
  /// ```swift
  /// @Shared(.sync(Todos())) var todos: IdentifiedArrayOf<Todo>
  /// ```
  ///
  /// For simpler querying needs, you can skip the ceremony of defining a ``SharingFirestoreSync/KeyCollectionRequest`` and
  /// use a directly configuration query with ``Sharing/SharedReaderKey/sync(configuration:database:)-3j44i`` or
  /// ``Sharing/SharedReaderKey/sync(configuration:database:)-3c82j``, instead.
  ///
  /// - Parameters:
  ///   - request: A request describing the data to sync.
  ///   - database: The database to sync from. A value of `nil` will use the
  ///     ``Dependencies/DependencyValues/defaultFirestore``.
  /// - Returns: A key that can be passed to the `@Shared` property wrapper.
  public static func sync<Records: RangeReplaceableCollection & Sendable>(
    _ request: some SharingFirestoreSync.KeyCollectionRequest<Records.Element>,
    database: Firestore? = nil
  ) -> Self
  where Self == SyncCollectionKey<Records>.Default {
    Self[SyncCollectionKey(request: request, database: database), default: Value()]
  }

  /// A key that can sync for collection data in a Firestore database.
  ///
  /// ```swift
  /// @Shared(
  ///   .sync(
  ///     configuration: .init(
  ///       collectionPath: "todos",
  ///       orderBy: .desc("createdAt"),
  ///       animation: .default
  ///     )
  ///   )
  /// )
  /// private var todos: IdentifiedArrayOf<Todo>
  /// ```
  ///
  /// For more flexible querying needs, see ``Sharing/SharedReaderKey/sync(_:database:)-385la``.
  ///
  /// - Parameters:
  ///   - configuration: A configuration describing the data to sync.
  ///   - database: The database to read from. A value of `nil` will use the
  ///     ``Dependencies/DependencyValues/defaultFirestore``.
  /// - Returns: A key that can be passed to the `@Shared` property wrapper.
  public static func sync<Value: Codable & DocumentIdentifiable & Sendable>(
    configuration: SharingFirestoreSync.CollectionConfiguration<Value>,
    database: Firestore? = nil
  ) -> Self
  where Self == SyncCollectionKey<IdentifiedArrayOf<Value>>.Default {
    Self[
      SyncCollectionKey(
        request: SyncCollectionConfigurationRequest(configuration: configuration),
        database: database
      ),
      default: []
    ]
  }

  /// A key that can sync for collection data in a Firestore database.
  ///
  /// ```swift
  /// @Shared(
  ///   .sync(
  ///     configuration: .init(
  ///       collectionPath: "todos",
  ///       orderBy: .desc("createdAt"),
  ///       animation: .default
  ///     )
  ///   )
  /// )
  /// private var todos: [Todo]
  /// ```
  ///
  /// For more flexible querying needs, see ``Sharing/SharedReaderKey/sync(_:database:)-385la``.
  ///
  /// - Parameters:
  ///   - configuration: A configuration describing the data to sync.
  ///   - database: The database to read from. A value of `nil` will use the
  ///     ``Dependencies/DependencyValues/defaultFirestore``.
  /// - Returns: A key that can be passed to the `@Shared` property wrapper.
  public static func sync<Value: Codable & DocumentIdentifiable & Sendable>(
    configuration: SharingFirestoreSync.CollectionConfiguration<Value>,
    database: Firestore? = nil
  ) -> Self
  where Self == SyncCollectionKey<[Value]>.Default {
    Self[
      SyncCollectionKey(
        request: SyncCollectionConfigurationRequest(configuration: configuration),
        database: database
      ),
      default: []
    ]
  }

  /// A key that can sync for document data in a Firestore database.
  ///
  /// This key takes a ``SharingFirestoreSync/KeyDocumentRequest`` conformance, which you define yourself. It has a single
  /// requirement that describes syncing a value from a database connection. For examples, we can
  /// define an `Todos` request that uses Firestore's query builder to fetch some items:
  ///
  /// ```swift
  /// struct TodoDocument: SharingFirestoreSync.KeyDocumentRequest {
  ///   typealias Value = Todo
  ///   let configuration: SharingFirestoreSync.DocumentConfiguration<Value> = .init(
  ///     collectionPath: "todos",
  ///     documentId: "docId",
  ///     animation: .default
  ///   )
  /// }
  /// ```
  ///
  /// And one can query for this data by wrapping the request in this key and provide it to the
  /// `@Shared` property wrapper:
  ///
  /// ```swift
  /// @Shared(.sync(TodoDocument())) private var todo: Todo = .init(memo: "", completed: false)
  /// ```
  ///
  /// For simpler querying needs, you can skip the ceremony of defining a ``SharingFirestoreSync/KeyDocumentRequest`` and
  /// use a directly configuration query with ``Sharing/SharedReaderKey/sync(configuration:database:)-4pwe``, instead.
  ///
  /// - Parameters:
  ///   - request: A request describing the data to sync.
  ///   - database: The database to sync from. A value of `nil` will use the
  ///     ``Dependencies/DependencyValues/defaultFirestore``.
  /// - Returns: A key that can be passed to the `@Shared` property wrapper.
  public static func sync<Value: Codable & Sendable>(
    _ request: some SharingFirestoreSync.KeyDocumentRequest<Value>,
    database: Firestore? = nil
  ) -> Self
  where Self == SyncDocumentKey<Value> {
    SyncDocumentKey(request: request, database: database)
  }

  /// A key that can sync for collection data in a Firestore database.
  ///
  /// ```swift
  /// @Shared(
  ///   .sync(
  ///     configuration: .init(
  ///       collectionPath: "todos",
  ///       documentId: "docId",
  ///       animation: .default
  ///     )
  ///   )
  /// ) private var todo: Todo = .init(
  ///   memo: "",
  ///   completed: false
  /// )
  /// ```
  ///
  /// For more flexible querying needs, see ``Sharing/SharedReaderKey/sync(_:database:)-6gnuz``.
  ///
  /// - Parameters:
  ///   - configuration: A configuration describing the data to sync.
  ///   - database: The database to read from. A value of `nil` will use the
  ///     ``Dependencies/DependencyValues/defaultFirestore``.
  /// - Returns: A key that can be passed to the `@Shared` property wrapper.
  public static func sync<Value: Codable & Sendable>(
    configuration: SharingFirestoreSync.DocumentConfiguration<Value>,
    database: Firestore? = nil
  ) -> Self
  where Self == SyncDocumentKey<Value> {
    SyncDocumentKey(
      request: SyncDocumentConfigurationRequest(configuration: configuration),
      database: database
    )
  }
}

/// A type defining a reader of Firestore queries.
///
/// You typically do not refer to this type directly, and will use
/// [`sync with request`](<doc:Sharing/SharedReaderKey/sync(_:database:)-385la>),
/// [`sync with configuration, for Array `](<doc:Sharing/SharedReaderKey/sync(configuration:database:)-3j44i>), and
/// [`sync with configuration, for IdenfiedArray`](<doc:Sharing/SharedReaderKey/sync(configuration:database:)-3c82j>) to create instances,
/// instead.
public struct SyncCollectionKey<Value: RangeReplaceableCollection & Sendable>: SharedKey
where Value.Element: Codable & DocumentIdentifiable & Sendable {
  typealias Element = Value.Element
  let database: Firestore
  let request: any SharingFirestoreSync.KeyCollectionRequest<Element>

  public typealias ID = UniqueRequestKeyID

  public var id: ID {
    ID(database: database, request: request)
  }

  init(
    request: some SharingFirestoreSync.KeyCollectionRequest<Element>,
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
      withResume {
        continuation.resumeReturningInitialValue()
      }
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
    guard Auth.auth(app: database.app).currentUser != nil else {
      withResume {
        continuation.resumeReturningInitialValue()
      }
      return
    }
    Task {
      do {
        let source = configuration.source
        var query: FirebaseFirestore.Query = database.collection(
          configuration.collectionPath
        )
        if let orderBy = configuration.orderBy {
          query = query.order(by: orderBy.field, descending: orderBy.isDescending)
        }
        let snapshot = try await query.getDocuments(
          source: source
        )
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
        if let configuration = request.configuration {
          var query: FirebaseFirestore.Query = database.collection(
            configuration.collectionPath
          )
          if let orderBy = configuration.orderBy {
            query = query.order(by: orderBy.field, descending: orderBy.isDescending)
          }
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
              try? $0.data(as: Element.self)
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

  public func save(
    _ value: Value,
    context: SaveContext,
    continuation: SaveContinuation
  ) {
    guard
      Auth.auth(app: database.app).currentUser != nil,
      let configuration = request.configuration
    else {
      return
    }
    Task {
      do {
        let collectionPath = configuration.collectionPath
        let snapshot = try await database.collection(collectionPath).getDocuments()
        let storedIds: Set<String> = Set(snapshot.documents.compactMap(\.documentID))
        let currentIds: Set<String> = Set(value.compactMap(\.documentId))
        let idsToDelete = storedIds.subtracting(currentIds)
        let idsToUpdate = currentIds.intersection(storedIds)

        let insertItems = value.filter { $0.documentId == nil }
        let insertDocuments: [DocumentReference] = insertItems.map { _ in
          database.collection(collectionPath).document()
        }

        let batch = database.batch()
        for id in idsToDelete {
          batch.deleteDocument(database.collection(collectionPath).document(id))
        }
        for (ref, data) in zip(insertDocuments, insertItems) {
          try batch.setData(from: data, forDocument: ref, merge: true)
        }
        for id in idsToUpdate {
          guard let data = value.first(where: { $0.documentId == id }) else {
            continue
          }
          let ref: DocumentReference = database.collection(collectionPath).document(id)
          try batch.setData(from: data, forDocument: ref, merge: true)
        }
        try await batch.commit()
        withResume {
          continuation.resume()
        }
      } catch {
        withResume {
          continuation.resume(throwing: error)
        }
      }
    }
  }
}

/// A type defining a reader of Firestore queries.
///
/// You typically do not refer to this type directly, and will use
/// [`sync with request`](<doc:Sharing/SharedReaderKey/sync(_:database:)-385la>),
/// [`sync with configuration `](<doc:Sharing/SharedReaderKey/sync(configuration:database:)-4pwe>)  to create instances,
/// instead.
public struct SyncDocumentKey<Value: Codable & Sendable>: SharedKey {
  let database: Firestore
  let request: any SharingFirestoreSync.KeyDocumentRequest<Value>

  public typealias ID = UniqueRequestKeyID

  public var id: ID {
    ID(database: database, request: request)
  }

  init(
    request: some SharingFirestoreSync.KeyDocumentRequest<Value>,
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
      withResume {
        continuation.resumeReturningInitialValue()
      }
      return
    }
    guard !isTesting else {
      if let testingValue = configuration.testingValue {
        withResume {
          continuation.resume(returning: testingValue)
        }
      } else {
        withResume {
          continuation.resumeReturningInitialValue()
        }
      }
      return
    }
    guard Auth.auth(app: database.app).currentUser != nil else {
      withResume {
        continuation.resumeReturningInitialValue()
      }
      return
    }
    Task {
      do {
        let source = configuration.source
        let collectionPath = configuration.collectionPath
        let documentId = configuration.documentId
        let value = try await database.collection(collectionPath).document(documentId).getDocument(
          as: Value.self,
          source: source
        )
        withResume {
          continuation.resume(returning: value)
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
        if let configuration = request.configuration {
          let collectionPath = configuration.collectionPath
          let documentId = configuration.documentId
          let registration = database.collection(collectionPath).document(documentId)
            .addSnapshotListener { snapshot, error in
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
              do {
                let value = try snapshot.data(as: Value.self)
                withResume {
                  subscriber.yield(value)
                }
              } catch {
                withResume {
                  subscriber.yield(throwing: error)
                }
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

  public func save(
    _ value: Value,
    context: SaveContext,
    continuation: SaveContinuation
  ) {
    guard
      Auth.auth(app: database.app).currentUser != nil,
      let configuration = request.configuration
    else {
      return
    }
    Task {
      do {
        let collectionPath = configuration.collectionPath
        let documentId = configuration.documentId
        try database.collection(collectionPath).document(documentId).setData(
          from: value,
          merge: true
        )
        withResume {
          continuation.resume()
        }
      } catch {
        withResume {
          continuation.resume(throwing: error)
        }
      }
    }
  }
}

private struct SyncCollectionConfigurationRequest<
  Element: Codable & DocumentIdentifiable & Sendable
>: SharingFirestoreSync.KeyCollectionRequest {

  internal init(
    configuration: SharingFirestoreSync.CollectionConfiguration<Element>
  ) {
    self.configuration = configuration
  }

  internal var configuration: SharingFirestoreSync.CollectionConfiguration<Element>?
}

private struct SyncDocumentConfigurationRequest<Element: Codable & Sendable>: SharingFirestoreSync
    .KeyDocumentRequest
{

  internal init(
    configuration: SharingFirestoreSync.DocumentConfiguration<Element>
  ) {
    self.configuration = configuration
  }

  internal var configuration: SharingFirestoreSync.DocumentConfiguration<Element>?
}
