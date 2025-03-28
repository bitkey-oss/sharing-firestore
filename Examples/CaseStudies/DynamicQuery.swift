import Dependencies
@preconcurrency import SharingFirestore
import SwiftUI

private let collectionPath = "dynamic-facts"

struct DynamicQueryDemo: SwiftUICaseStudy {
  let readMe = """
    This demo shows how to perform a dynamic query using the tools provided by the library. Every 3 seconds, \
    a fact about a number is loaded from the network and saved to Firestore. You can search the \
    facts for specific text, and the list will stay in sync so that if a new fact is added to the database \
    that satisfies your search criteria, it will immediately appear.

    To achieve this, you can call the `load` method defined on the `@SharedReader` projected \
    value to set a new query with dynamic parameters. You can also swipe to delete items.
    """
  let caseStudyTitle = "Dynamic Query"

  @State.SharedReader(value: []) private var facts: [Fact]
  @State var query = ""
  @State var totalCount = 0
  @State var searchCount = 0

  @Dependency(\.defaultFirestore) var database

  var body: some View {
    List {
      Section {
        if query.isEmpty {
          Text("Facts: \(totalCount)")
            .contentTransition(.numericText(value: Double(totalCount)))
            .font(.largeTitle)
            .bold()
        } else {
          Text("Search: \(facts.count)")
            .contentTransition(.numericText(value: Double(facts.count)))
          Text("Facts: \(totalCount)")
            .contentTransition(.numericText(value: Double(totalCount)))
        }
      }
      Section {
        ForEach(facts) { fact in
          Text(fact.body)
        }
        .onDelete { indexSet in
          Task {
            do {
              let factsToDelete = indexSet.map { facts[$0] }
              let batch = database.batch()
              for fact in factsToDelete {
                if let documentId = fact.id {
                  let ref = database.collection(collectionPath).document(documentId)
                  batch.deleteDocument(ref)
                }
              }
              try await batch.commit()
            } catch {
              print("Error deleting facts: \(error)")
            }
          }
        }
      }
    }
    .searchable(text: $query)
    .task(id: query) {
      await withErrorReporting {
        try await $facts.load(.query(FactsQuery(searchText: query)))
      }
    }
    .task {
      let listener: LockIsolated<(any ListenerRegistration)?> = .init(nil)
      do {
        try await withTaskCancellationHandler {
          // Monitor the total count of facts
          let reg = database
            .collection(collectionPath)
            .addSnapshotListener { snapshot, error in
            if let error = error {
              print("Error fetching total count: \(error)")
              return
            }
            self.totalCount = snapshot?.documents.count ?? 0
          }
          listener.setValue(reg)
          
          // Add facts every second
          var number = 0
          while true {
            try await Task.sleep(for: .seconds(3))
            number += 1
            let fact = try await String(
              decoding: URLSession.shared
                .data(from: URL(string: "http://numberapi.com/\(number)")!).0,
              as: UTF8.self
            )
            
            let newFact = Fact(
              body: fact,
              createdAt: Date()
            )
            
            try database.collection(collectionPath).addDocument(from: newFact)
          }
        } onCancel: {
          listener.withValue {
            $0?.remove()
            $0 = nil
          }
        }
      } catch {}
    }
  }

  private struct FactsQuery: SharingFirestoreQuery.KeyRequest {
    var searchText: String

    var configuration: SharingFirestoreQuery.Configuration<Fact> {
      .init(
        path: collectionPath,
        predicates: [.order(by: "createdAt", descending: true)],
        animation: .default
      )
    }

    func query(_ db: Firestore) throws -> Query {
      let query = db.collection(configuration.path)

      // Apply base predicates
      var resultQuery = applingPredicated(query)

      // Apply search filter if needed
      if !searchText.isEmpty {
        // In a real app, you might use a specialized solution for text search
        // Here we're doing a simple filter for demonstration
        resultQuery = resultQuery.whereField("body", isGreaterThanOrEqualTo: searchText)
                                .whereField("body", isLessThanOrEqualTo: searchText + "\u{f8ff}")
      }

      return resultQuery
    }
  }
}

private struct Fact: Codable, Sendable, Identifiable {
  @DocumentID var id: String?
  var body: String
  var createdAt: Date
}

#Preview {
  let _ = prepareDependencies(prepareFirestore(_:))
  NavigationStack {
    CaseStudyView {
      DynamicQueryDemo()
    }
  }
}
