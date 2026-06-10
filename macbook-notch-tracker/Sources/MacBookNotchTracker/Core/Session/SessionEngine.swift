import Foundation
import Observation

@Observable
final class SessionEngine {
    private let sessionStore: SessionStoring
    private let notificationService: NotificationServicing

    private(set) var activeSession: ActiveSession?
    private(set) var sessionHistory: [SessionRecord]
    private var breakRemindersEnabled: Bool
    private var breakReminderMinutes: Int

    init(
        sessionStore: SessionStoring,
        notificationService: NotificationServicing,
        breakRemindersEnabled: Bool,
        breakReminderMinutes: Int = 60
    ) {
        self.sessionStore = sessionStore
        self.notificationService = notificationService
        self.breakRemindersEnabled = breakRemindersEnabled
        self.breakReminderMinutes = breakReminderMinutes

        let snapshot = sessionStore.loadSnapshot()
        self.activeSession = snapshot.activeSession
        self.sessionHistory = snapshot.sessionHistory

        if
            breakRemindersEnabled,
            activeSession?.state == .running || activeSession?.state == .extended
        {
            notificationService.scheduleBreakReminder(after: breakReminderMinutes)
        }
    }

    var currentState: SessionState {
        activeSession?.state ?? .idle
    }

    var todaySummary: SessionSummary {
        summary(for: .day)
    }

    func handle(_ command: AppCommand) {
        switch command {
        case .startSession:
            startSession()
        case .stopSession:
            stopSession()
        case .pauseSession:
            updateActiveState(.paused)
        case .resumeSession:
            updateActiveState(.running)
        case .extendSession:
            updateActiveState(.extended)
        case .startBreak:
            startBreak()
            notificationService.clearBreakReminder()
        case .endBreak:
            endBreak()
            if breakRemindersEnabled {
                notificationService.scheduleBreakReminder(after: breakReminderMinutes)
            }
        case .openDashboard, .toggleNotchPreview, .selectDashboardSection:
            break
        }
    }

    func updateSettings(_ settings: AppSettings) {
        let wasEnabled = breakRemindersEnabled
        breakRemindersEnabled = settings.breakRemindersEnabled
        breakReminderMinutes = settings.breakReminderMinutes

        guard breakRemindersEnabled else {
            notificationService.clearBreakReminder()
            return
        }

        if
            (activeSession?.state == .running || activeSession?.state == .extended),
            wasEnabled || breakRemindersEnabled
        {
            notificationService.scheduleBreakReminder(after: breakReminderMinutes)
        }
    }

    func summary(for range: SummaryRange, now: Date = .now) -> SessionSummary {
        let records = records(in: range, now: now)

        return SessionSummary(
            totalTracked: records
                .filter { $0.state != .onBreak }
                .reduce(0) { $0 + $1.duration },
            totalBreak: records
                .filter { $0.state == .onBreak }
                .reduce(0) { $0 + $1.duration },
            sessionsCount: records.count
        )
    }

    func filteredHistory(_ filter: SessionHistoryFilter, now: Date = .now) -> [SessionRecord] {
        records(in: filter.range, now: now).filter { record in
            let matchesState = filter.state.map { record.state == $0 } ?? true
            return matchesState
        }
    }

    func chartPoints(for range: SummaryRange, now: Date = .now) -> [SessionChartPoint] {
        let grouped = Dictionary(grouping: records(in: range, now: now)) { record in
            chartLabel(for: record.startedAt, range: range)
        }

        return grouped.keys.sorted().map { label in
            let records = grouped[label] ?? []

            return SessionChartPoint(
                label: label,
                trackedDuration: records
                    .filter { $0.state != .onBreak }
                    .reduce(0) { $0 + $1.duration },
                breakDuration: records
                    .filter { $0.state == .onBreak }
                    .reduce(0) { $0 + $1.duration },
                sessionCount: records.count
            )
        }
    }

    func recentHistory(limit: Int = 5) -> [SessionRecord] {
        Array(sessionHistory.prefix(limit))
    }

    func updateRecord(_ updatedRecord: SessionRecord) {
        guard let index = sessionHistory.firstIndex(where: { $0.id == updatedRecord.id }) else { return }

        var normalizedRecord = updatedRecord
        normalizedRecord.endedAt = max(normalizedRecord.endedAt, normalizedRecord.startedAt)
        normalizedRecord.updatedAt = .now

        sessionHistory[index] = normalizedRecord
        sessionHistory.sort { $0.startedAt > $1.startedAt }
        persistSnapshot()
    }

    @discardableResult
    func deleteRecord(id: UUID) -> SessionRecord? {
        guard let index = sessionHistory.firstIndex(where: { $0.id == id }) else { return nil }

        let deletedRecord = sessionHistory.remove(at: index)
        persistSnapshot()

        return deletedRecord
    }

    func restoreRecord(_ record: SessionRecord) {
        sessionHistory.append(record)
        sessionHistory.sort { $0.startedAt > $1.startedAt }
        persistSnapshot()
    }

    private func startSession() {
        guard activeSession == nil else { return }

        activeSession = ActiveSession(
            id: UUID(),
            startedAt: .now,
            state: .running
        )

        persistSnapshot()

        if breakRemindersEnabled {
            notificationService.scheduleBreakReminder(after: breakReminderMinutes)
        }
    }

    private func stopSession() {
        guard let activeSession else { return }

        appendRecord(from: activeSession, endedAt: .now)
        self.activeSession = nil
        persistSnapshot()
        notificationService.clearBreakReminder()
    }

    private func startBreak() {
        guard
            let activeSession,
            activeSession.state == .running || activeSession.state == .extended
        else {
            return
        }

        let transitionDate = Date.now
        appendRecord(from: activeSession, endedAt: transitionDate)

        self.activeSession = ActiveSession(
            id: UUID(),
            startedAt: transitionDate,
            state: .onBreak
        )

        persistSnapshot()
    }

    private func endBreak() {
        guard let activeSession, activeSession.state == .onBreak else { return }

        let transitionDate = Date.now
        appendRecord(from: activeSession, endedAt: transitionDate)

        self.activeSession = ActiveSession(
            id: UUID(),
            startedAt: transitionDate,
            state: .running
        )

        persistSnapshot()
    }

    private func updateActiveState(_ state: SessionState) {
        guard canTransition(to: state) else { return }
        activeSession?.state = state

        persistSnapshot()

        if
            breakRemindersEnabled,
            state == .running || state == .extended
        {
            notificationService.scheduleBreakReminder(after: breakReminderMinutes)
        } else if state == .onBreak || state == .paused {
            notificationService.clearBreakReminder()
        }
    }

    private func appendRecord(from session: ActiveSession, endedAt: Date) {
        let record = SessionRecord(
            id: session.id,
            startedAt: session.startedAt,
            endedAt: max(endedAt, session.startedAt),
            state: session.state,
            createdAt: session.startedAt,
            updatedAt: endedAt,
            notes: nil
        )

        sessionHistory.insert(record, at: 0)
    }

    private func canTransition(to newState: SessionState) -> Bool {
        guard let activeSession else { return false }

        return switch (activeSession.state, newState) {
        case (.running, .paused),
             (.running, .extended),
             (.running, .onBreak),
             (.extended, .running),
             (.extended, .paused),
             (.extended, .onBreak),
             (.paused, .running),
             (.onBreak, .running):
            true
        case let (current, next) where current == next:
            true
        default:
            false
        }
    }

    private func persistSnapshot() {
        sessionStore.saveSnapshot(
            SessionStoreSnapshot(
                schemaVersion: 1,
                activeSession: activeSession,
                sessionHistory: sessionHistory
            )
        )
    }

    private func records(in range: SummaryRange, now: Date) -> [SessionRecord] {
        let allRecords = historicalRecordsIncludingActive(now: now)
        let calendar = Calendar.current

        return allRecords.filter { record in
            switch range {
            case .day:
                return calendar.isDate(record.startedAt, inSameDayAs: now)
            case .week:
                guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: now) else { return false }
                return weekInterval.contains(record.startedAt)
            case .month:
                guard let monthInterval = calendar.dateInterval(of: .month, for: now) else { return false }
                return monthInterval.contains(record.startedAt)
            }
        }
        .sorted { $0.startedAt > $1.startedAt }
    }

    private func historicalRecordsIncludingActive(now: Date) -> [SessionRecord] {
        var records = sessionHistory

        if let activeSession {
            records.insert(
                SessionRecord(
                    id: activeSession.id,
                    startedAt: activeSession.startedAt,
                    endedAt: now,
                    state: activeSession.state,
                    createdAt: activeSession.startedAt,
                    updatedAt: now,
                    notes: nil
                ),
                at: 0
            )
        }

        return records
    }

    private func chartLabel(for date: Date, range: SummaryRange) -> String {
        let formatter = DateFormatter()

        switch range {
        case .day:
            formatter.dateFormat = "HH:mm"
        case .week:
            formatter.dateFormat = "EEE"
        case .month:
            formatter.dateFormat = "MMM d"
        }

        return formatter.string(from: date)
    }
}
