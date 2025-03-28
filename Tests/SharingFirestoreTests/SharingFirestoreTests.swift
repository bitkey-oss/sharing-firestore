 import Dependencies
 import Sharing
 @preconcurrency import SharingFirestore
 import Testing

 @Suite struct FirestoreSharingTests {
   @Test
   func query() async throws {
     try await withDependencies {
       let options = FirebaseOptions(googleAppID: "1:123:ios:123abc", gcmSenderID: "123")
       options.projectID = "demo-project"
       FirebaseApp.configure(options: options)
       Firestore.enableLogging(true)
       let settings = Firestore.firestore().settings
       let gcsettings = MemoryLRUGCSettings(sizeBytes: 20 * 1024 * 1024 as NSNumber)
       settings.cacheSettings = MemoryCacheSettings(garbageCollectorSettings: gcsettings)
       settings.host = "127.0.0.1:8080"
       settings.isSSLEnabled = false
       Firestore.firestore().settings = settings
       $0.defaultFirestore = Firestore.firestore()
     } operation: {
       @Shared(
         .sync(
           configuration: .init(
             collectionPath: "todos",
             orderBy: .desc("createdAt"),
             animation: .default
           )
         )
       )
       var todos: [Todo]
       try await Task.sleep(nanoseconds: 10_000_000)
       #expect(todos.isEmpty)
       #expect($todos.loadError == nil)
     }
   }
 }

 private struct Todo: Sendable, Codable, DocumentIdentifiable {
   var clientId: UUID = .init()
   @DocumentID var documentId: String?
   var memo: String
   var completed: Bool
   var createdAt: Date = .init()
 }
