import SwiftUI

@MainActor
@main
struct MacBookNotchTrackerApp: App {
    @State private var container: AppContainer

    init() {
        let container = AppContainer()
        _container = State(initialValue: container)
        container.islandSceneController.install(container: container)
    }

    var body: some Scene {
        WindowGroup("Dashboard", id: AppWindowID.dashboard) {
            DashboardRootView()
                .environment(container)
                .preferredColorScheme(.dark)
        }
        .defaultSize(width: 1180, height: 760)

        MenuBarExtra("Notch Tracker", systemImage: "timer") {
            MenuBarContentView()
                .environment(container)
        }

        Settings {
            SettingsPlaceholderView()
                .environment(container)
                .preferredColorScheme(.dark)
        }
    }
}
