import Dependencies
import SharingFirestore
import SwiftUI

struct ObservableModelDemo: SwiftUICaseStudy {
  let readMe = """
    This demo shows how to use the `@SharedReader` and `@Shared` property wrappers in an `@Observable` model. \
    In SwiftUI, the `@Query` macro only works when installed directly in a SwiftUI view and \
    cannot be used outside of views.

    The tools provided by this library work virtually anywhere, including in `@Observable` \
    models and UIKit view controllers. You can switch between segments to see both query and sync behaviors in action.
    """
  let caseStudyTitle = "@Observable Model"

  @State private var model = Model()

  @State var selectedLayout: SegmentType = .query
  enum SegmentType: CaseIterable {
    case query
    case sync
  }

  private var facts: [Todo] {
    switch selectedLayout {
    case .query:
      return model.queryFacts
    case .sync:
      return model.facts
    }
  }

  var body: some View {
    Picker("Layout", selection: $selectedLayout) {
      Text("クエリ")
        .tag(SegmentType.query)
      Text("同期")
        .tag(SegmentType.sync)
    }.pickerStyle(SegmentedPickerStyle())

    List {
      Section {
        Text("Facts: \(facts.count)")
          .font(.largeTitle)
          .bold()
          .contentTransition(.numericText(value: Double(facts.count)))
      }
      switch selectedLayout {
      case .query:
        Section {
          ForEach(model.queryFacts) { fact in
            Button {
              model.toggle(fact: fact)
            } label: {
              Text(fact.memo)
            }
          }
        }
      case .sync:
        Section {
          ForEach(model.facts) { fact in
            Button {
              model.toggle(fact: fact)
            } label: {
              HStack {
                Image(systemName: fact.completed ? "checkmark.square" : "square")
                Text(fact.memo)
              }
            }
          }
          .onDelete { indices in
            model.deleteFact(indices: indices)
          }
        }
      }
    }
    .task {
      do {
        while true {
          try await Task.sleep(for: .seconds(3))
          await model.increment()
        }
      } catch {}
    }
  }
}

@Observable
@MainActor
private class Model {
  @ObservationIgnored
  @SharedReader(
    .query(
      configuration: .init(
        path: "todos",
        predicates: [
          .isEqualTo("completed", .bool(true)),
          .order(by: "createdAt", descending: true)
        ],
        animation: .default
      )
    )
  )
  var queryFacts: [Todo]
  @ObservationIgnored
  @Shared(
    .sync(
      configuration: .init(
        collectionPath: "todos",
        orderBy: .desc("createdAt"),
        animation: .default
      )
    )
  )
  var facts: [Todo]
  var number = 0

  func increment() async {
    number += 1
    await withErrorReporting {
      let fact = try await String(
        decoding: URLSession.shared
          .data(from: URL(string: "http://numberapi.com/\(number)")!).0,
        as: UTF8.self
      )
      $facts.withLock {
        $0.append(.init(memo: "\(number): \(fact)", completed: false))
      }
    }
  }

  func deleteFact(indices: IndexSet) {
    _ = withErrorReporting {
      $facts.withLock {
        $0.remove(atOffsets: indices)
      }
    }
  }

  func toggle(fact: Todo) {
    withAnimation {
      $facts.withLock {
        guard let index = $0.firstIndex(where: { $0.clientId == fact.clientId }) else { return }
        $0[index].completed.toggle()
      }
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
