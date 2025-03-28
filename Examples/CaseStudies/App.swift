import SharingFirestore
import SwiftUI
import Dependencies

func prepareFirestore(_ values: inout DependencyValues) {
  let options = FirebaseOptions(googleAppID: "1:123:ios:123abc", gcmSenderID: "123")
  options.projectID = "demo-project"
  FirebaseApp.configure(options: options)
  let settings = Firestore.firestore().settings
  settings.cacheSettings = MemoryCacheSettings()
  settings.host = "127.0.0.1:8080"
  settings.isSSLEnabled = false
  Firestore.firestore().settings = settings
  values.defaultFirestore = Firestore.firestore()
}

@main
struct CaseStudiesApp: App {
  
  init() {
     prepareDependencies(prepareFirestore(_:))
  }
  
  var body: some Scene {
    WindowGroup {
      NavigationStack {
        Form {
          NavigationLink("Query Demo") {
            CaseStudyView {
              SwiftUIQueryDemo()
            }
          }
          NavigationLink("Sync Demo") {
            CaseStudyView {
              SwiftUISyncDemo()
            }
          }
          NavigationLink("Observable Demo") {
            CaseStudyView {
              ObservableModelDemo()
            }
          }
          NavigationLink("Dynamic Query Demo") {
            CaseStudyView {
              DynamicQueryDemo()
            }
          }
        }
      }
    }
  }
}
