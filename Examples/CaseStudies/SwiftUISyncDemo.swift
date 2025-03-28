import Dependencies
import SharingFirestore
import SwiftUI

struct SwiftUISyncDemo: SwiftUICaseStudy {
  let readMe = """
    This demo shows how to use the `@Shared` annotation directly in a SwiftUI view to leverage the bidirectional sync functionality. \
    This tool monitors changes to the Firestore database and automatically updates the state and re-renders the view when the table changes.

    You can also add new Todos, and delete them by swiping on a row and tapping the "Delete" button. \
    Both single document (`todo`) and multiple document (`todos` collection) sync operations are implemented.
    """
  let caseStudyTitle = "SwiftUI Views"

  @Shared(
    .sync(
      configuration: .collection(
        path: "todos",
        orderBy: .desc("createdAt"),
        animation: .default
      )
    )
  )
  private var todos: IdentifiedArrayOf<Todo>

  @Shared(
    .sync(
      configuration: .document(
        collectionPath: "single-todos",
        documentId: "demo",
        animation: .default
      )
    )
  )
  private var todo: Todo = .init(memo: "", completed: false)

  @State private var newTodo = ""

  @Dependency(\.defaultFirestore) var database

  var body: some View {
    List {
      Section {
        Text("Todos: \(todos.count)")
          .font(.largeTitle)
          .bold()
          .contentTransition(.numericText(value: Double(todos.count)))
      }
      Section {
        HStack {
          Button("Add", systemImage: "plus.circle.fill") {
            _ = $todos.withLock {
              $0.insert(Todo(memo: newTodo, completed: false), at: 0)
            }
            newTodo = ""
          }
          .disabled(newTodo.isEmpty)
          TextField("New Todo", text: $newTodo)
        }
      }
      Section {
        ForEach(Binding($todos)) { $todo in
          TextFieldCell.init(todos: $todos, todo: $todo)
        }
      }
    }
  }
}

private struct TextFieldCell: View {
  @Shared var todos: IdentifiedArrayOf<Todo>
  @Binding var todo: Todo

  var body: some View {
    HStack {
      HStack {
        Text(todo.completed ? "✅" : "❌")
        TextField("Existed Memo", text: $todo.memo)
      }
    }
    .swipeActions(edge: .leading) {
      Button {
        todo.completed.toggle()
      } label: {
        Image(
          systemName: todo.completed ? "checkmark.square" : "square"
        )
      }
      .tint(.green)
    }
    .swipeActions(edge: .trailing) {
      Button("Delete") {
        $todos.withLock {
          _ = $0.remove(id: todo.id)
        }
      }
      .tint(.red)
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

#Preview {
  NavigationStack {
    CaseStudyView {
      SwiftUISyncDemo()
    }
  }
}
