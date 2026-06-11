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
    var settingsDraft: AppSettings
    var selectedSection: DashboardSection

    private var workScheduleTimer: Timer?
    private var lastAutomaticStartDayIdentifier: String?
    private var lastAutomaticStopDayIdentifier: String?
    private var scheduleObserversInstalled = false

    var commandRouter: AppCommandRouter {
        AppCommandRouter(container: self)
    }

    init(
        settingsStore: SettingsStoring = JSONSettingsStore(),
        sessionStore: SessionStoring = JSONSessionStore(),
        notificationService: NotificationServicing = NotificationService(),
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
        self.settingsDraft = loadedSettings
        self.selectedSection = sectionRegistry.sections.first ?? .overview
        self.islandStateMachine = IslandStateMachine()
        self.sessionEngine = SessionEngine(
            sessionStore: sessionStore,
            notificationService: notificationService,
            breakRemindersEnabled: loadedSettings.breakRemindersEnabled,
            breakReminderMinutes: loadedSettings.breakReminderMinutes
        )

        islandStateMachine.onStateChanged = { [weak self] in
            self?.synchronizeIslandScene()
        }
        islandStateMachine.updateSettings(loadedSettings)
        notificationService.requestAuthorizationIfNeeded()
        launchAtLoginController.setEnabled(loadedSettings.launchAtLoginEnabled)
        startWorkScheduleMonitoring()
        installScheduleObserversIfNeeded()
        synchronizeIslandScene()
        synchronizeAutomaticWorkSchedule()
    }

    func saveSettings(_ settings: AppSettings) {
        let previousSettings = self.settings

        self.settings = settings
        self.settingsDraft = settings
        settingsStore.saveSettings(settings)
        sessionEngine.updateSettings(settings)
        islandStateMachine.updateSettings(settings)
        launchAtLoginController.setEnabled(settings.launchAtLoginEnabled)

        if settings.workdayStartMinutes != previousSettings.workdayStartMinutes
            || settings.workdayEndMinutes != previousSettings.workdayEndMinutes
            || settings.holidayDates != previousSettings.holidayDates
        {
            lastAutomaticStartDayIdentifier = nil
            lastAutomaticStopDayIdentifier = nil
        }

        let scheduleSettingsChanged =
            settings.automaticWorkTimerEnabled != previousSettings.automaticWorkTimerEnabled ||
            settings.workdayStartMinutes != previousSettings.workdayStartMinutes ||
            settings.workdayEndMinutes != previousSettings.workdayEndMinutes ||
            settings.holidayDates != previousSettings.holidayDates

        synchronizeAutomaticWorkSchedule(allowCatchUpStart: false)

        if scheduleSettingsChanged {
            startWorkScheduleMonitoring()
        }
    }

    func commitSettingsDraft() {
        saveSettings(settingsDraft)
    }

    func discardSettingsDraft() {
        settingsDraft = settings
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
        workScheduleTimer = nil

        guard let nextCheckDate = nextAutomaticScheduleCheckDate(from: .now) else { return }

        let delay = max(0.05, nextCheckDate.timeIntervalSinceNow)

        let timer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.handleWorkScheduleTimerFired()
            }
        }

        timer.tolerance = 0.15
        workScheduleTimer = timer
    }

    private func handleWorkScheduleTimerFired() {
        synchronizeAutomaticWorkSchedule(allowCatchUpStart: true)
        startWorkScheduleMonitoring()
    }

    private func installScheduleObserversIfNeeded() {
        guard !scheduleObserversInstalled else { return }
        scheduleObserversInstalled = true

        NotificationCenter.default.addObserver(
            forName: NSApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            self.synchronizeAutomaticWorkSchedule(allowCatchUpStart: true)
            self.startWorkScheduleMonitoring()
        }

        NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didWakeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            self.synchronizeAutomaticWorkSchedule(allowCatchUpStart: true)
            self.startWorkScheduleMonitoring()
        }
    }

    private func synchronizeAutomaticWorkSchedule(now: Date = .now, allowCatchUpStart: Bool = true) {
        guard settings.automaticWorkTimerEnabled else { return }
        guard settings.workdayEndMinutes > settings.workdayStartMinutes else { return }
        guard isAutomaticWorkday(now) else { return }

        let dayIdentifier = automaticScheduleDayIdentifier(for: now)
        let startDate = scheduledDate(for: settings.workdayStartMinutes, on: now)
        let endDate = scheduledDate(for: settings.workdayEndMinutes, on: now)

        if now >= endDate {
            guard sessionEngine.activeSession != nil else { return }
            guard lastAutomaticStopDayIdentifier != dayIdentifier else { return }

            sessionEngine.handle(.stopSession)
            lastAutomaticStopDayIdentifier = dayIdentifier
            return
        }

        guard now >= startDate else { return }
        guard now < endDate else { return }
        guard allowCatchUpStart || now <= startDate.addingTimeInterval(2) else { return }
        guard sessionEngine.currentState == .idle else { return }
        guard lastAutomaticStartDayIdentifier != dayIdentifier else { return }

        sessionEngine.handle(.startSession)
        lastAutomaticStartDayIdentifier = dayIdentifier
    }

    private func nextAutomaticScheduleCheckDate(from now: Date) -> Date? {
        guard settings.automaticWorkTimerEnabled else { return nil }
        guard settings.workdayEndMinutes > settings.workdayStartMinutes else { return nil }

        if isAutomaticWorkday(now) {
            let startDate = scheduledDate(for: settings.workdayStartMinutes, on: now)
            let endDate = scheduledDate(for: settings.workdayEndMinutes, on: now)

            if now < startDate {
                return startDate
            }

            if now < endDate {
                return endDate
            }
        }

        let calendar = Calendar.current
        var candidate = calendar.startOfDay(for: now)

        for _ in 0..<14 {
            guard let nextDay = calendar.date(byAdding: .day, value: 1, to: candidate) else { break }
            candidate = nextDay

            if isAutomaticWorkday(candidate) {
                return scheduledDate(for: settings.workdayStartMinutes, on: candidate)
            }
        }

        return nil
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
