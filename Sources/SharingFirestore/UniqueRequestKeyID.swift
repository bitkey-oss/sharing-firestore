/// A value that uniquely identifies a fetch key.
public struct UniqueRequestKeyID: Hashable {
  fileprivate let databaseID: ObjectIdentifier
  fileprivate let request: AnyHashable
  fileprivate let requestTypeID: ObjectIdentifier

  internal init(
    database: Firestore,
    request: some Hashable
  ) {
    self.databaseID = ObjectIdentifier(database)
    self.request = AnyHashable(request)
    self.requestTypeID = ObjectIdentifier(type(of: request))
  }
}
