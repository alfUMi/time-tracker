import Foundation
import Observation

@MainActor
@Observable
final class AppContainer {
    let settingsStore: SettingsStoring
    let islandSceneController: IslandSceneControlling
    let launchAtLoginController: LaunchAtLoginControlling
    let sectionRegistry: DashboardSectionRegistry
    let sessionEngine: SessionEngine
    let islandStateMachine: IslandStateMachine

    var settings: AppSettings
    var selectedSection: DashboardSection

    var commandRouter: AppCommandRouter {
        AppCommandRouter(container: self)
    }

    init(
        settingsStore: SettingsStoring = JSONSettingsStore(),
        sessionStore: SessionStoring = JSONSessionStore(),
        notificationService: NotificationServicing = NotificationServiceStub(),
        launchAtLoginController: LaunchAtLoginControlling = LaunchAtLoginControllerStub(),
        islandSceneController: IslandSceneControlling? = nil,
        sectionRegistry: DashboardSectionRegistry = .default
    ) {
        let loadedSettings = settingsStore.loadSettings()

        self.settingsStore = settingsStore
        self.launchAtLoginController = launchAtLoginController
        self.islandSceneController = islandSceneController ?? IslandSceneController()
        self.sectionRegistry = sectionRegistry
        self.settings = loadedSettings
        self.selectedSection = sectionRegistry.sections.first ?? .overview
        self.islandStateMachine = IslandStateMachine()
        self.sessionEngine = SessionEngine(
            sessionStore: sessionStore,
            notificationService: notificationService,
            breakReminderMinutes: loadedSettings.breakReminderMinutes
        )

        islandStateMachine.onStateChanged = { [weak self] in
            self?.synchronizeIslandScene()
        }
        islandStateMachine.updateSettings(loadedSettings)
        notificationService.requestAuthorizationIfNeeded()
        synchronizeIslandScene()
    }

    func saveSettings(_ settings: AppSettings) {
        self.settings = settings
        settingsStore.saveSettings(settings)
        sessionEngine.updateSettings(settings)
        islandStateMachine.updateSettings(settings)
        launchAtLoginController.setEnabled(settings.launchAtLoginEnabled)
    }

    var isNotchPreviewVisible: Bool {
        islandStateMachine.isExpanded
    }

    func toggleNotchPreview() {
        islandStateMachine.togglePinnedExpansion()
    }

    func expandIsland() {
        islandStateMachine.expandFromInteraction()
    }

    func handleIslandHotzone(_ isHovering: Bool) {
        islandStateMachine.hotzoneHoverChanged(isHovering)
    }

    func handleIslandHover(_ isHovering: Bool) {
        islandStateMachine.islandHoverChanged(isHovering)
    }

    func handleIslandFocus(_ isFocused: Bool) {
        islandStateMachine.contentFocusChanged(isFocused)
    }

    func collapseIsland() {
        islandStateMachine.collapseToNotch()
    }

    private func synchronizeIslandScene() {
        islandSceneController.updateSceneState(islandStateMachine.sceneState)
    }
}
