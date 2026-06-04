import Foundation

enum IslandSceneState: Equatable {
    case hidden
    case notch
    case compactIsland
    case expandedIsland
}

protocol SessionStoring {
    func loadSnapshot() -> SessionStoreSnapshot
    func saveSnapshot(_ snapshot: SessionStoreSnapshot)
}

protocol SettingsStoring {
    func loadSettings() -> AppSettings
    func saveSettings(_ settings: AppSettings)
}

protocol NotificationServicing {
    func requestAuthorizationIfNeeded()
    func scheduleBreakReminder(after minutes: Int)
    func clearBreakReminder()
}

protocol LaunchAtLoginControlling {
    func setEnabled(_ enabled: Bool)
}

@MainActor
protocol IslandSceneControlling {
    func install(container: AppContainer)
    func updateSceneState(_ state: IslandSceneState)
}
