import Dependencies
import SharingFirestore
import SwiftUI

struct SwiftUIQueryDemo: SwiftUICaseStudy {
  let readMe = """
    This demo shows how to use the `@SharedReader` annotation directly in a SwiftUI view to query Firestore data. \
    This tool monitors database changes and automatically updates the UI when the database is updated.

    Every second, a new fact about a number is loaded via API and saved to Firestore. \
    The `@SharedReader` is configured to always display the top 3 results with animation.
    """
  let caseStudyTitle = "SwiftUI Views"

  private struct FactFetch: SharingFirestoreQuery.KeyRequest {
    let configuration = SharingFirestoreQuery.Configuration<Fact>(
      path: "/facts",
      predicates: [
        .order(by: "count", descending: true),
      ],
      animation: .default
    )

    func query(_ db: Firestore) throws -> Query {
      let ref = db.collection(configuration.path)
      let query = applingPredicated(ref)
      return query.limit(to: 3)
    }
  }

//  @SharedReader(.query(FactFetch()))
//  private var facts: [Fact]

  @SharedReader(
    .query(
      configuration: .init(
        path: "facts",
        predicates: [
          .or([
            .isEqualTo("count", .integer(3)),
            .isNotEqualTo("mm", .null)
          ])
        ],
        animation: .default
      )
    )
  )
  private var facts: IdentifiedArrayOf<Fact>

  @Dependency(\.defaultFirestore) var database

  var body: some View {
    List {
      Section {
        Text("Facts: \(facts.count)")
          .font(.largeTitle)
          .bold()
          .contentTransition(.numericText(value: Double(facts.count)))
      }
      Section {
        ForEach(facts) { fact in
          Text(fact.body)
        }
      }
    }
    .task {
      do {
        var number = 0
        while true {
          try await Task.sleep(for: .seconds(1))
          number += 1
          let fact = try await String(
            decoding: URLSession.shared
              .data(from: URL(string: "http://numberapi.com/\(number)")!).0,
            as: UTF8.self
          )
          try database.collection("facts").addDocument(from: Fact(count: number, body: fact))
        }
      } catch {}
    }
  }
}

private struct Fact: Sendable, Codable, Identifiable {
  @DocumentID var id: String?
  var count: Int?
  var body: String
}

#Preview {
  NavigationStack {
    CaseStudyView {
      SwiftUIQueryDemo()
    }
  }
}
