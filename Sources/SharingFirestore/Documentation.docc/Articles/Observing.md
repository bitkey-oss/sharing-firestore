# Observing changes to model data

Firestore changes can be easily observed by integrating with frameworks like SwiftUI, UIKit, and more.

## Overview

SharingFirestore provides several ways to observe changes to Firestore data in different contexts of your application. This is especially powerful because Firestore's real-time capabilities are seamlessly integrated with various Swift UI frameworks.

  * [SwiftUI](#SwiftUI)
  * [@Observable models](#@Observable-models)
  * [UIKit](#UIKit)
  * [Combining multiple observations](#Combining-multiple-observations)

### SwiftUI

The `@SharedReader` property wrapper works in SwiftUI views to observe Firestore queries. You simply add a property to the view annotated with `@SharedReader`:

```swift
struct FactsView: View {
  @SharedReader(
    .query(
      configuration: .init(
        path: "facts",
        predicates: [.order(by: "count", descending: true)],
        animation: .default
      )
    )
  )
  var facts: IdentifiedArrayOf<Fact>

  var body: some View {
    List {
      ForEach(facts) { fact in
        Text(fact.body)
      }
    }
  }
}
```

The SwiftUI view will automatically re-render whenever the Firestore collection changes. The `animation` parameter allows you to specify how these changes are animated in the UI.

For bidirectional synchronization, you can use `@Shared`:

```swift
struct TodoListView: View {
  @Shared(
    .sync(
      configuration: .init(
        collectionPath: "todos",
        orderBy: ("createdAt", true),
        animation: .default
      )
    )
  )
  private var todos: IdentifiedArrayOf<Todo>

  @State private var newTodoText = ""

  var body: some View {
    VStack {
      HStack {
        TextField("New Todo", text: $newTodoText)
        Button("Add") {
          guard !newTodoText.isEmpty else { return }
          $todos.withLock {
            $0.insert(Todo(memo: newTodoText, completed: false), at: 0)
          }
          newTodoText = ""
        }
      }.padding()

      List {
        ForEach(Binding($todos)) { $todo in
          HStack {
            Button {
              todo.completed.toggle()
            } label: {
              Image(systemName: todo.completed ? "checkmark.square" : "square")
            }
            TextField("Todo", text: $todo.memo)
          }
          .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
              $todos.withLock {
                _ = $0.remove(id: todo.id)
              }
            } label: {
              Label("Delete", systemImage: "trash")
            }
          }
        }
      }
    }
  }
}
```

### @Observable models

Both `@SharedReader` and `@Shared` work with `@Observable` models and legacy `ObservableObject` classes. When used in an `@Observable` model, you need to apply the `@ObservationIgnored` attribute to prevent conflicts with Swift's macro system:

```swift
@Observable
class TodosModel {
  @ObservationIgnored
  @SharedReader(
    .query(
      configuration: .init(
        path: "todos",
        predicates: [
          .isEqualTo("completed", true),
          .order(by: "createdAt", descending: true)
        ],
        animation: .default
      )
    )
  )
  var completedTodos: [Todo]

  @ObservationIgnored
  @Shared(
    .sync(
      configuration: .init(
        collectionPath: "todos",
        orderBy: ("createdAt", true),
        animation: .default
      )
    )
  )
  var allTodos: [Todo]

  func addTodo(memo: String) {
    $allTodos.withLock {
      $0.append(Todo(memo: memo, completed: false))
    }
  }

  func deleteTodo(at indices: IndexSet) {
    $allTodos.withLock {
      $0.remove(atOffsets: indices)
    }
  }

  func toggleCompletion(for todo: Todo) {
    $allTodos.withLock {
      guard let index = $0.firstIndex(where: { $0.clientId == todo.clientId }) else { return }
      $0[index].completed.toggle()
    }
  }
}
```

You can then use this model in your SwiftUI views:

```swift
struct TodosView: View {
  @State private var model = TodosModel()
  @State private var newTodo = ""

  var body: some View {
    List {
      Section(header: Text("Add Todo")) {
        HStack {
          TextField("New Todo", text: $newTodo)
          Button("Add") {
            guard !newTodo.isEmpty else { return }
            model.addTodo(memo: newTodo)
            newTodo = ""
          }
        }
      }

      Section(header: Text("All Todos")) {
        ForEach(model.allTodos) { todo in
          Button {
            model.toggleCompletion(for: todo)
          } label: {
            HStack {
              Image(systemName: todo.completed ? "checkmark.square" : "square")
              Text(todo.memo)
            }
          }
        }
        .onDelete { indices in
          model.deleteTodo(at: indices)
        }
      }

      Section(header: Text("Completed Todos")) {
        ForEach(model.completedTodos) { todo in
          Text(todo.memo)
        }
      }
    }
  }
}
```

### UIKit

SharingFirestore also works with UIKit view controllers. For example, with a `UITableViewController`:

```swift
class TodosViewController: UITableViewController {
  @SharedReader(
    .query(
      configuration: .init(
        path: "todos",
        predicates: [.order(by: "createdAt", descending: true)]
      )
    )
  )
  private var todos: [Todo] = []

  override func viewDidLoad() {
    super.viewDidLoad()
    setupTableView()

    // Observe changes to todos
    $todos.publisher.sink { [weak self] _ in
      self?.tableView.reloadData()
    }
    .store(in: &cancellables)
  }

  private var cancellables = Set<AnyCancellable>()

  // ... rest of UITableViewController implementation
}
```

If you're already using the [Swift Navigation](https://github.com/pointfreeco/swift-navigation) library, you can use its `observe` method instead of Combine:

```swift
override func viewDidLoad() {
  super.viewDidLoad()
  setupTableView()

  // Observe changes to todos
  observe { [weak self] in
    guard let self else { return }
    self.tableView.reloadData()
  }
}
```

### Combining multiple observations

You can combine multiple Firestore observations in a single view or model to build complex UIs:

```swift
struct DashboardView: View {
  // Active tasks from Firestore
  @SharedReader(
    .query(
      configuration: .init(
        path: "tasks",
        predicates: [
          .isEqualTo("status", "active"),
          .order(by: "priority", descending: true)
        ],
        animation: .default
      )
    )
  )
  var activeTasks: [Task]

  // User preferences document
  @Shared(
    .sync(
      configuration: .init(
        collectionPath: "preferences",
        documentId: "user-123",
        animation: .default
      )
    )
  )
  var preferences: UserPreferences = UserPreferences()

  // Team members
  @SharedReader(
    .query(
      configuration: .init(
        path: "team",
        predicates: [.order(by: "name", descending: false)],
        animation: .default
      )
    )
  )
  var teamMembers: [TeamMember]

  var body: some View {
    // Build UI using all these observed data sources
  }
}
```

This approach allows you to create reactive UIs that automatically update when any of the Firestore data sources change.
