import AppKit
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

    private var workScheduleTimer: Timer?
    private var lastAutomaticStartDayIdentifier: String?
    private var lastAutomaticStopDayIdentifier: String?
    private var lastAutomaticScheduleCheckAt: Date?

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
        launchAtLoginController.setEnabled(loadedSettings.launchAtLoginEnabled)
        lastAutomaticScheduleCheckAt = .now
        startWorkScheduleMonitoring()
        synchronizeIslandScene()
        synchronizeAutomaticWorkSchedule()
    }

    func saveSettings(_ settings: AppSettings) {
        let previousSettings = self.settings

        self.settings = settings
        settingsStore.saveSettings(settings)
        sessionEngine.updateSettings(settings)
        islandStateMachine.updateSettings(settings)
        launchAtLoginController.setEnabled(settings.launchAtLoginEnabled)

        if settings.automaticWorkTimerEnabled && !previousSettings.automaticWorkTimerEnabled {
            lastAutomaticScheduleCheckAt = .now
        } else if !settings.automaticWorkTimerEnabled {
            lastAutomaticScheduleCheckAt = nil
        }

        synchronizeAutomaticWorkSchedule()
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

    @discardableResult
    func focusDashboardWindow() -> Bool {
        NSApp.activate(ignoringOtherApps: true)

        if let dashboardWindow = NSApp.windows.first(where: {
            $0.identifier?.rawValue == AppWindowID.dashboard || $0.title == "Dashboard"
        }) {
            dashboardWindow.makeKeyAndOrderFront(nil)
            dashboardWindow.makeFirstResponder(dashboardWindow.contentView)
            return true
        }

        return false
    }

    private func synchronizeIslandScene() {
        islandSceneController.updateSceneState(islandStateMachine.sceneState)
    }

    private func startWorkScheduleMonitoring() {
        workScheduleTimer?.invalidate()

        let timer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.synchronizeAutomaticWorkSchedule()
            }
        }

        timer.tolerance = 5
        workScheduleTimer = timer
    }

    private func synchronizeAutomaticWorkSchedule(now: Date = .now) {
        defer {
            lastAutomaticScheduleCheckAt = now
        }

        guard settings.automaticWorkTimerEnabled else { return }
        guard settings.workdayEndMinutes > settings.workdayStartMinutes else { return }
        guard isAutomaticWorkday(now) else { return }

        let dayIdentifier = automaticScheduleDayIdentifier(for: now)
        let startDate = scheduledDate(for: settings.workdayStartMinutes, on: now)
        let endDate = scheduledDate(for: settings.workdayEndMinutes, on: now)
        let didCrossStartBoundary = {
            guard let lastAutomaticScheduleCheckAt else { return false }
            return lastAutomaticScheduleCheckAt < startDate && now >= startDate
        }()

        if now >= endDate {
            guard sessionEngine.activeSession != nil else { return }
            guard lastAutomaticStopDayIdentifier != dayIdentifier else { return }

            sessionEngine.handle(.stopSession)
            lastAutomaticStopDayIdentifier = dayIdentifier
            return
        }

        guard now >= startDate else { return }
        guard now < endDate else { return }
        guard didCrossStartBoundary else { return }
        guard sessionEngine.currentState == .idle else { return }
        guard lastAutomaticStartDayIdentifier != dayIdentifier else { return }

        sessionEngine.handle(.startSession(taskLabel: "Scheduled Work"))
        lastAutomaticStartDayIdentifier = dayIdentifier
    }

    private func isAutomaticWorkday(_ date: Date) -> Bool {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: date)

        guard (2...6).contains(weekday) else {
            return false
        }

        let today = calendar.startOfDay(for: date)

        return !settings.holidayDates.contains {
            calendar.isDate(calendar.startOfDay(for: $0), inSameDayAs: today)
        }
    }

    private func scheduledDate(for minutes: Int, on date: Date) -> Date {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let hours = minutes / 60
        let remainingMinutes = minutes % 60

        return calendar.date(
            bySettingHour: hours,
            minute: remainingMinutes,
            second: 0,
            of: startOfDay
        ) ?? startOfDay
    }

    private func automaticScheduleDayIdentifier(for date: Date) -> String {
        let components = Calendar.current.dateComponents([.year, .month, .day], from: date)
        let year = components.year ?? 0
        let month = components.month ?? 0
        let day = components.day ?? 0

        return "\(year)-\(month)-\(day)"
    }
}
